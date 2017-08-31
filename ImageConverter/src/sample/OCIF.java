package sample;

import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import sample.Palette;


public class OCIF {
    private static void writePixelToFileAsOCIF1(FileOutputStream out, Pixel pixel) throws IOException {
//        out.write((byte) pixel.background.red);
//        out.write((byte) pixel.background.green);
//        out.write((byte) pixel.background.blue);
//        out.write((byte) pixel.foreground.red);
//        out.write((byte) pixel.foreground.green);
//        out.write((byte) pixel.foreground.blue);

        out.write((byte) Palette.getClosestIndex(pixel.background));
        out.write((byte) Palette.getClosestIndex(pixel.foreground));

        out.write((byte) pixel.alpha);
        out.write(pixel.symbol.getBytes(StandardCharsets.UTF_8));
    }


    private static byte[] integerToByteArray(int number, int arraySize) {
        byte[] array = new byte[arraySize];

        int position = arraySize - 1;
        do {
            array[position] = (byte) (number & 0xFF);
            number = number >> 8;
            position--;
        } while (number > 0);

        while (position >= 0) {
            array[position] = 0x0;
            position--;
        }

        return array;
    }

    private static void writeGroupedImage(FileOutputStream out, HashMap<Integer, HashMap<String, HashMap<Integer, HashMap<Integer, HashMap<Integer, ArrayList<Integer>>>>>> groupedImage) throws IOException {
        // Alphas size
        out.write(groupedImage.keySet().size());

        for (Integer alpha : groupedImage.keySet()) {
            // Alpha
            out.write(alpha.byteValue());
            // Symbols size
            out.write(integerToByteArray(groupedImage.get(alpha).keySet().size(), 2));

            for (String symbol : groupedImage.get(alpha).keySet()) {
                // Symbol
                out.write(symbol.getBytes(StandardCharsets.UTF_8));
                // Backgrounds size
                out.write((byte) groupedImage.get(alpha).get(symbol).keySet().size());

                for (Integer background : groupedImage.get(alpha).get(symbol).keySet()) {
                    // Background
                    out.write(background.byteValue());
                    // Foregrounds size
                    out.write((byte) groupedImage.get(alpha).get(symbol).get(background).keySet().size());

                    for (Integer foreground : groupedImage.get(alpha).get(symbol).get(background).keySet()) {
                        // Foreground
                        out.write(foreground.byteValue());
                        // Ys size
                        out.write((byte) groupedImage.get(alpha).get(symbol).get(background).get(foreground).keySet().size());

                        for (Integer y : groupedImage.get(alpha).get(symbol).get(background).get(foreground).keySet()) {
                            // Y
                            out.write(y.byteValue());
                            // Xs size
                            out.write((byte) groupedImage.get(alpha).get(symbol).get(background).get(foreground).get(y).size());

                            for (Integer x : groupedImage.get(alpha).get(symbol).get(background).get(foreground).get(y)) {
                                // X
                                out.write(x.byteValue());

                            }
                        }
                    }
                }
            }
        }
    }

    private static void OCIF1ConvertAsBraille(FileOutputStream out, sample.Image image) throws IOException {
        for (int y = 0; y < image.height; y += 4) {
            for (int x = 0; x < image.width; x += 2) {
                writePixelToFileAsOCIF1(out, sample.Image.getBraillePixel(image, x, y));
            }
        }
    }

    private static void OCIF1ConvertAsSemiPixel(FileOutputStream out, sample.Image image) throws IOException {
        for (int y = 0; y < image.height; y += 2) {
            for (int x = 0; x < image.width; x++) {
                writePixelToFileAsOCIF1(out, sample.Image.getSemiPixel(image, x, y));
            }
        }
    }

    public static void convert(String imagePath, String convertedImagePath, int requestedWidth, int requestedHeight, int encodingMethod, boolean convertAsBraille, boolean enableDithering, double ditheringIntensity) throws IOException {
        FileOutputStream out = new FileOutputStream(convertedImagePath);

        out.write("OCIF".getBytes(StandardCharsets.US_ASCII));
        out.write((byte) encodingMethod);

        if (encodingMethod == 5) {
            out.write(integerToByteArray(requestedWidth, 2));
            out.write(integerToByteArray(requestedHeight, 2));
        } else {
            out.write((byte) requestedWidth);
            out.write((byte) requestedHeight);
        }

        sample.Image image = new sample.Image(new javafx.scene.image.Image(imagePath,
                requestedWidth * (convertAsBraille ? 2 : 1),
                requestedHeight * (convertAsBraille ? 4 : 2),
                false,
                true
        ));

        if (enableDithering) {
            image = sample.Image.dither(image, ditheringIntensity);
        }

        if (convertAsBraille) {
            if (encodingMethod == 5) {
                OCIF1ConvertAsBraille(out, image);
            } else {
                writeGroupedImage(out, sample.Image.groupAsBraille(image));
            }
        } else {
            if (encodingMethod == 5) {
                OCIF1ConvertAsSemiPixel(out, image);
            } else {
                writeGroupedImage(out, sample.Image.groupAsSemiPixel(image));
            }
        }

        out.close();
    }
}
