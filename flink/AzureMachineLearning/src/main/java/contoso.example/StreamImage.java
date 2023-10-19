package contoso.example;

import ai.djl.modality.cv.Image;
import java.util.UUID;


public class StreamedImage {

    private Image image;
    private String id;
    private String sourceFilePath;
    public StreamedImage(Image image,String id, String sourceFilePath) {
        this.image = image;
        this.id = UUID.randomUUID().toString();
        this.sourceFilePath = sourceFilePath;
    }

    public String getId() {
        return id;
    }

    public Image getImage() {
        return image;
    }

    public String getSourceFilePath() {  // New getter for the source file path
        return sourceFilePath;
    }
    @Override
    public String toString() {
        return id;
    }
}
