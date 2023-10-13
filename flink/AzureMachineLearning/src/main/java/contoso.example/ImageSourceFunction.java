package contoso.example;

import org.apache.flink.streaming.api.functions.source.RichSourceFunction;
import java.io.File;


public class ImageSourceFunction extends RichSourceFunction<String> {
    private volatile boolean isRunning = true;

    @Override
    public void run(SourceContext<String> ctx) throws Exception {
        while (isRunning) {

           String imagePath  = "abfs://<container>@<ADLSgen2 account>.dfs.core.windows.net/data/dataset/multilabelFridgeObjects/Images/";
            File dir = new File(imagePath);
            File[] files = dir.listFiles((d, name) -> name.endsWith(".jpg"));
            if (files != null) {
                for (File file : files) {
                    ctx.collect(file.getAbsolutePath());
                }
            }
            Thread.sleep(10000);  // sleep for a while before scanning the directory again
        }
    }

    @Override
    public void cancel() {
        isRunning = false;
    }
}

