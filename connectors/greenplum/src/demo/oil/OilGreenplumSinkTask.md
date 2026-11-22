# OilGreenplumSinkTask

Транзакционно записывает STG, партию и checkpoint. При старте продолжает от авторитетной позиции GP; ошибки offsets останавливают обработку.

Исходный код: [OilGreenplumSinkTask.java](OilGreenplumSinkTask.java).
