package demo.iceberg;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.PosixFilePermission;
import java.util.Map;
import org.apache.iceberg.rest.HTTPHeaders;
import org.apache.iceberg.rest.HTTPRequest;
import org.apache.iceberg.rest.ImmutableHTTPRequest;
import org.apache.iceberg.rest.RESTClient;
import org.apache.iceberg.rest.auth.AuthManager;
import org.apache.iceberg.rest.auth.AuthSession;
import org.apache.iceberg.rest.auth.OAuth2Util;
import org.apache.iceberg.rest.responses.OAuthTokenResponse;

/** Demo: on-demand client_credentials renewal for Iceberg 1.9.2; fail closed. */
public final class CiamAuthManager implements AuthManager {

  private static final String ENDPOINT =
    "https://dp-103.mcs.local/iam/hydra/oauth2/token";
  private static final String AUDIENCE = "92d0c90a-3720-4831-9885-fde8aeb98a99";

  public CiamAuthManager(String ignoredName) {}

  @Override
  public AuthSession catalogSession(
    RESTClient client,
    Map<String, String> props
  ) {
    String path = props.get("ciam.credential-file");
    if (
      path == null || !path.startsWith("/etc/kafka-demo/")
    ) throw new IllegalArgumentException("approved credential path required");
    return new Session(
      client.withAuthSession(AuthSession.EMPTY),
      Path.of(path)
    );
  }

  @Override
  public void close() {}

  private static final class Session implements AuthSession {

    private final RESTClient client;
    private final Path credentialFile;
    private String token;
    private long renewAt;

    Session(RESTClient client, Path credentialFile) {
      this.client = client;
      this.credentialFile = credentialFile;
    }

    @Override
    public synchronized HTTPRequest authenticate(HTTPRequest request) {
      if (
        !"https".equals(request.requestUri().getScheme()) ||
        !"10.0.2.16".equals(request.requestUri().getHost())
      ) throw new IllegalArgumentException("unapproved LakeKeeper destination");
      if (System.currentTimeMillis() >= renewAt) {
        try {
          Path real = credentialFile.toRealPath();
          if (
            !real.getParent().equals(Path.of("/etc/kafka-demo"))
          ) throw new IllegalStateException();
          for (PosixFilePermission p : Files.getPosixFilePermissions(real))
            if (
              p.name().startsWith("GROUP_") || p.name().startsWith("OTHERS_")
            ) throw new IllegalStateException();
          String credential = Files.readString(credentialFile).trim();
          if (!credential.contains(":")) throw new IllegalStateException();
          OAuthTokenResponse result = OAuth2Util.fetchToken(
            client,
            Map.of(),
            credential,
            "lakekeeper",
            ENDPOINT,
            Map.of("audience", AUDIENCE)
          );
          Integer ttl = result.expiresInSeconds();
          if (
            result.token() == null || ttl == null || ttl <= 0
          ) throw new IllegalStateException();
          token = result.token();
          renewAt = System.currentTimeMillis() + Math.max(1000L, ttl * 750L);
        } catch (Exception ex) {
          token = null;
          renewAt = 0;
          throw new IllegalStateException("CIAM credential renewal failed");
        }
      }
      HTTPHeaders h = request
        .headers()
        .putIfAbsent(HTTPHeaders.of(OAuth2Util.authHeaders(token)));
      return ImmutableHTTPRequest.builder().from(request).headers(h).build();
    }

    @Override
    public synchronized void close() {
      token = null;
      renewAt = 0;
    }
  }
}
