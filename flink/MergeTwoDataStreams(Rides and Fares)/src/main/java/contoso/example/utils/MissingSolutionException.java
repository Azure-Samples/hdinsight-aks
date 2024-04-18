package contoso.example.utils;

/** Exception denoting a missing solution (results in tests verifying the solution instead). */
public class MissingSolutionException extends Exception {
    /** Create new exception. */
    public MissingSolutionException() {}

    /** Determine if the root cause of a failure is a MissingSolutionException. */
    public static boolean ultimateCauseIsMissingSolution(Throwable e) {
        while (e != null) {
            if (e instanceof MissingSolutionException) {
                return true;
            } else {
                e = e.getCause();
            }
        }
        return false;
    }
}
