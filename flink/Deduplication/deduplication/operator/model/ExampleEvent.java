package deduplication.operator.model;

/**
 * An example event to show how deduplication works.
 */
public class ExampleEvent {
    public Integer id;
    public Long timestamp;

    public ExampleEvent(Integer id) {
        this.id = id;
        this.timestamp = System.currentTimeMillis();
    }
}
