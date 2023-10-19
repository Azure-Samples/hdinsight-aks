package contoso.example;

import ai.djl.modality.cv.Image;
import ai.djl.modality.cv.ImageFactory;
import org.apache.flink.connector.file.src.reader.StreamFormat;
import org.apache.flink.core.fs.FSDataInputStream;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.annotation.Nullable;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.UUID;

public final class ImageReader implements StreamFormat.Reader<StreamedImage> {

    private static final Logger logger = LoggerFactory.getLogger(ImageReader.class);

    private final FSDataInputStream in;
    private final String filePath;

    ImageReader(FSDataInputStream in, String filePath) {
        this.in = in;
        this.filePath = filePath;
    }

    @Nullable
    @Override
    public StreamedImage read() throws IOException {
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        int nRead;
        byte[] data = new byte[16384];

        while ((nRead = in.read(data, 0, data.length)) != -1) {
            buffer.write(data, 0, nRead);
        }

        buffer.flush();
        byte[] allBytes = buffer.toByteArray();

        if(allBytes.length == 0) {
            return null;
        }

        try {
            // read all bytes as needed for image
            Image image = ImageFactory.getInstance().fromInputStream(new ByteArrayInputStream(allBytes));

            // Define id here
            String id = UUID.randomUUID().toString(); // or any other way you generate ids

            return new StreamedImage(image, id, filePath);
        } catch(Exception ex) {
            logger.error(ex.getLocalizedMessage());
            return null;
        }
    }

    @Override
    public void close() throws IOException {
        in.close();
    }
}


