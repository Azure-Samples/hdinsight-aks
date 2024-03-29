package contoso.example;

import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.connector.file.src.FileSourceSplit;
import org.apache.flink.connector.file.src.reader.BulkFormat;
import org.apache.flink.connector.file.src.util.RecordAndPosition;
import org.apache.flink.core.fs.Path;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

public class ImageStreamFormat implements BulkFormat<ImageDataWithPath, FileSourceSplit> {

    // read image data and its associated file path from a file system.
    @Override
    public Reader createReader(Configuration config, FileSourceSplit split) throws IOException {
   
        // The Reader reads the image data from the file system using an FSDataInputStream
        return new Reader() {
            private final org.apache.flink.core.fs.FSDataInputStream stream;
            private boolean end = false;

            {
                Path filePath = split.path();
                this.stream = filePath.getFileSystem().open(filePath);
            }

            //  reads the entire image file into a byte array 
            @Override
            public RecordIterator<ImageDataWithPath> readBatch() throws IOException {
                return new RecordIterator<ImageDataWithPath>() {

                    @Override
                    public RecordAndPosition<ImageDataWithPath> next() {
                        byte[] bytes = new byte[0];
                        try {
                            bytes = readAllBytes(stream);
                        } catch (IOException e) {
                            throw new RuntimeException(e);
                        }
                        end = true;

                        // Since there's only one record, we set position to 0.
                        long position = 0;

                        // The size of the record is the length of the byte array.
                        long size = bytes.length;

                        return new RecordAndPosition<>(new ImageDataWithPath(bytes, split.path().toString()), position, size);
                    }

                    @Override
                    public void releaseBatch() {
                    }
                };
            }

            @Override
            public void close() throws IOException {
                if (this.stream != null) {
                    this.stream.close();
                }
            }
        };
    }
    // restores a reader from a checkpointed position
    @Override
    public Reader restoreReader(Configuration config, FileSourceSplit split) throws IOException {
        return createReader(config, split);
    }

    @Override
    public TypeInformation<ImageDataWithPath> getProducedType() {
        return TypeInformation.of(ImageDataWithPath.class);
    }

    //indicates whether the format is splittable. In this case, it returns false, meaning that the image files cannot be read in parallel.
    @Override
    public boolean isSplittable() {
        return false;
    }

    // creates an ImageDataWithPath object with this byte array and the file path
    private byte[] readAllBytes(org.apache.flink.core.fs.FSDataInputStream stream) throws IOException {
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        int nRead;
        byte[] data = new byte[16384];

        while ((nRead = stream.read(data, 0, data.length)) != -1) {
            buffer.write(data, 0, nRead);
        }

        buffer.flush();
        return buffer.toByteArray();
    }
}
