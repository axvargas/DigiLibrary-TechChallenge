@IsTest
private class NoAvailableCopiesExceptionTest {

    @IsTest
    static void exceptionShouldBeThrownAndCaught() {
        try {
            throw new NoAvailableCopiesException(
                'No available copies for this book.'
            );
        } catch (NoAvailableCopiesException excp) {
            Assert.areEqual(
                'No available copies for this book.',
                excp.getMessage(),
                'The excp message should match.'
            );
        }
    }
}