package contoso.example;

//  Associate an image’s binary data with its file path
public class ImageDataWithPath {
    public final byte[] imageData;
    public final String path;

    public ImageDataWithPath(byte[] imageData, String path) {
        this.imageData = imageData;
        this.path = path;
    }
}
