package sample;

import java.util.ArrayList;
import java.util.HashMap;

public class Image {
    public int width;
    public int height;
    public Color[][] pixels;

    public Image(javafx.scene.image.Image image) {
        this.width = (int) image.getWidth();
        this.height = (int) image.getHeight();
        this.pixels = new Color[this.height][this.width];

        for (int y = 0; y < this.height; y++) {
            for (int x = 0; x < this.width; x++) {
                this.pixels[y][x] = new Color(image.getPixelReader().getArgb(x, y));
            }
        }
    }

    private static String getBrailleChar(int a, int b, int c, int d, int e, int f, int g, int h) {
        return Character.toString((char) (10240 + 128 * h + 64 * g + 32 * f + 16 * d + 8 * b + 4 * e + 2 * c + a));
    }

    private static Color[][] getBraiileArray(Image image, int fromX, int fromY) {
        Color[][] brailleArray = new Color[4][2];
        int imageX, imageY;

        for (int y = 0; y < 4; y++) {
            for (int x = 0; x < 2; x++) {
                imageX = fromX + x;
                imageY = fromY + y;

                if (imageX < image.width && imageY < image.height) {
                    brailleArray[y][x] = image.pixels[imageY][imageX];
                } else {
                    brailleArray[y][x] = new Color(0x00000000);
                }
            }
        }

        return brailleArray;
    }

    private static double getColorDistance(Color myColor) {
        return Math.pow((double) myColor.red, 2) + Math.pow((double) myColor.green, 2) + Math.pow((double) myColor.blue, 2);
    }

    private static double getChannelsDelta(Color color1, Color color2) {
        return Math.pow((double) color1.red - color2.red, 2) + Math.pow((double) color1.green - color2.green, 2) + Math.pow((double) color1.blue - color2.blue, 2);
    }

    private static Color getBestMatch(Color color1, Color color2, Color targetColor) {
        return getChannelsDelta(color1, targetColor) < getChannelsDelta(color2, targetColor) ? color1 : color2;
    }

    static Pixel getBraillePixel(Image image, int fromX, int fromY) {
        Color[][] brailleArray = getBraiileArray(image, fromX, fromY);

        double distance, minDistance = 999999.0d, maxDistance = 0.0d;
        Color minColor = brailleArray[0][0], maxColor = brailleArray[0][0];

        for (int y = 0; y < 4; y++) {
            for (int x = 0; x < 2; x++) {
                distance = getColorDistance(brailleArray[y][x]);
                if (distance < minDistance) {
                    minDistance = distance;
                    minColor = brailleArray[y][x];
                }

                if (distance > maxDistance) {
                    maxDistance = distance;
                    maxColor = brailleArray[y][x];
                }
            }
        }

        int[][] brailleMatrix = new int[4][2];

        for (int y = 0; y < 4; y++) {
            for (int x = 0; x < 2; x++) {
                brailleMatrix[y][x] = getBestMatch(minColor, maxColor, brailleArray[y][x]) == minColor ? 0 : 1;
            }
        }

        String brailleChar = getBrailleChar(
                brailleMatrix[0][0], brailleMatrix[0][1],
                brailleMatrix[1][0], brailleMatrix[1][1],
                brailleMatrix[2][0], brailleMatrix[2][1],
                brailleMatrix[3][0], brailleMatrix[3][1]
        );


        return new Pixel(minColor, maxColor, 0x00, brailleChar);
    }

    private static final double Xp1Yp0 = 7.0d / 16.0d;
    private static final double Xp1Yp1 = 1.0d / 16.0d;
    private static final double Xp0Yp1 = 5.0d / 16.0d;
    private static final double Xm1Y1 = 3.0d / 16.0d;

    static Image dither(Image image, double intensity) {
        for (int y = 0; y < image.height; y++) {
            for (int x = 0; x < image.width; x++) {

                Color paletteColor = Palette.getClosestColor(image.pixels[y][x]);
                Color colorDifference = Color.difference(image.pixels[y][x], paletteColor);

                image.pixels[y][x] = paletteColor;

                if (x < image.width - 1) {
                    image.pixels[y][x + 1] = Color.sum(
                            image.pixels[y][x + 1],
                            Color.multiply(colorDifference, Xp1Yp0 * intensity)
                    );

                    if (y < image.height - 1) {
                        image.pixels[y + 1][x + 1] = Color.sum(
                                image.pixels[y + 1][x + 1],
                                Color.multiply(colorDifference, Xp1Yp1 * intensity)
                        );
                    }
                }

                if (y < image.height - 1) {
                    image.pixels[y + 1][x] = Color.sum(
                            image.pixels[y + 1][x],
                            Color.multiply(colorDifference, Xp0Yp1 * intensity)
                    );

                    if (x > 0) {
                        image.pixels[y + 1][x - 1] = Color.sum(
                                image.pixels[y + 1][x - 1],
                                Color.multiply(colorDifference, Xm1Y1 * intensity)
                        );
                    }
                }
            }
        }

        return image;
    }


    static Pixel getSemiPixel(Image image, int x, int y) {
        Color upper = image.pixels[y][x], lower = new Color(0xFF, 0x0, 0x0, 0x0);

        if (y < image.height) {
            lower = image.pixels[y + 1][x];
        }

        Pixel pixel = new Pixel(upper, lower, 0x00, "▄");

        if (upper.alpha == 0x00) {
            //Есть и наверху, и внизу
            if (lower.alpha == 0x00) {
                pixel.background = upper;
                pixel.foreground = lower;
                pixel.alpha = 0x00;
                pixel.symbol = "▄";
            }
            //Есть только наверху, внизу прозрачный
            else {
                pixel.background = upper;
                pixel.foreground = upper;
                pixel.alpha = 0xFF;
                pixel.symbol = "▀";
            }
        } else {
            //Нет наверху, но есть внизу
            if (lower.alpha == 0x00) {
                pixel.background = upper;
                pixel.foreground = lower;
                pixel.alpha = 0xFF;
                pixel.symbol = "▄";
            }
            //Нет ни наверху, ни внизу
            else {
                pixel.background = upper;
                pixel.foreground = lower;
                pixel.alpha = 0xFF;
                pixel.symbol = " ";
            }
        }

        return pixel;
    }

    private static HashMap<Integer, HashMap<String, HashMap<Integer, HashMap<Integer, HashMap<Integer, ArrayList<Integer>>>>>> fillHashMap(Integer alpha, String symbol, Integer background, Integer foreground, Integer y, Integer x) {
        ArrayList<Integer> xs = new ArrayList<>();

        HashMap<Integer, ArrayList<Integer>> ys = new HashMap<>();
        ys.put(y, xs);

        HashMap<Integer, HashMap<Integer, ArrayList<Integer>>> fs = new HashMap<>();
        fs.put(foreground, ys);

        HashMap<Integer, HashMap<Integer, HashMap<Integer, ArrayList<Integer>>>> bs = new HashMap<>();
        bs.put(background, fs);

        HashMap<String, HashMap<Integer, HashMap<Integer, HashMap<Integer, ArrayList<Integer>>>>> ss = new HashMap<>();
        ss.put(symbol, bs);

        HashMap<Integer, HashMap<String, HashMap<Integer, HashMap<Integer, HashMap<Integer, ArrayList<Integer>>>>>> as = new HashMap<>();
        as.put(alpha, ss);

        return as;
    }

    private static void groupPixel(HashMap<Integer, HashMap<String, HashMap<Integer, HashMap<Integer, HashMap<Integer, ArrayList<Integer>>>>>> groupedImage, Integer alpha, String symbol, Integer background, Integer foreground, Integer y, Integer x) {
        HashMap<Integer, HashMap<String, HashMap<Integer, HashMap<Integer, HashMap<Integer, ArrayList<Integer>>>>>> filledHashMap = fillHashMap(alpha, symbol, background, foreground, y, x);

        if (!groupedImage.containsKey(alpha)) {
            groupedImage.put(
                    alpha,
                    filledHashMap.get(alpha)
            );
        }

        if (!groupedImage.get(alpha).containsKey(symbol)) {
            groupedImage.get(alpha).put(
                    symbol,
                    filledHashMap.get(alpha).get(symbol)
            );
        }

        if (!groupedImage.get(alpha).get(symbol).containsKey(background)) {
            groupedImage.get(alpha).get(symbol).put(
                    background,
                    filledHashMap.get(alpha).get(symbol).get(background)
            );
        }

        if (!groupedImage.get(alpha).get(symbol).get(background).containsKey(foreground)) {
            groupedImage.get(alpha).get(symbol).get(background).put(
                    foreground,
                    filledHashMap.get(alpha).get(symbol).get(background).get(foreground)
            );
        }

        if (!groupedImage.get(alpha).get(symbol).get(background).get(foreground).containsKey(y)) {
            groupedImage.get(alpha).get(symbol).get(background).get(foreground).put(
                    y,
                    filledHashMap.get(alpha).get(symbol).get(background).get(foreground).get(y)
            );
        }

        groupedImage.get(alpha).get(symbol).get(background).get(foreground).get(y).add(x);
    }

    static HashMap<Integer, HashMap<String, HashMap<Integer, HashMap<Integer, HashMap<Integer, ArrayList<Integer>>>>>> groupAsBraille(Image image) {
        HashMap<Integer, HashMap<String, HashMap<Integer, HashMap<Integer, HashMap<Integer, ArrayList<Integer>>>>>> groupedImage = new HashMap<>();
        Pixel pixel;
        int xCounter = 1, yCounter = 1;

        for (int y = 0; y < image.height; y += 4) {
            for (int x = 0; x < image.width; x += 2) {
                pixel = getBraillePixel(image, x, y);
                groupPixel(groupedImage, pixel.alpha, pixel.symbol, Palette.getClosestIndex(pixel.background), Palette.getClosestIndex(pixel.foreground), yCounter, xCounter);

                xCounter++;
            }

            xCounter = 1;
            yCounter++;
        }

        return groupedImage;
    }

    static HashMap<Integer, HashMap<String, HashMap<Integer, HashMap<Integer, HashMap<Integer, ArrayList<Integer>>>>>> groupAsSemiPixel(Image image) {
        HashMap<Integer, HashMap<String, HashMap<Integer, HashMap<Integer, HashMap<Integer, ArrayList<Integer>>>>>> groupedImage = new HashMap<>();
        Pixel pixel;
        int yCounter = 1;

        for (int y = 0; y < image.height; y += 2) {
            for (int x = 0; x < image.width; x++) {
                pixel = getSemiPixel(image, x, y);
                groupPixel(groupedImage, pixel.alpha, pixel.symbol, Palette.getClosestIndex(pixel.background), Palette.getClosestIndex(pixel.foreground), yCounter, x + 1);
            }

            yCounter++;
        }

        return groupedImage;
    }
}