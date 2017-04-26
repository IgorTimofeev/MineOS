package sample;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.CheckBox;
import javafx.scene.control.TextField;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.stage.FileChooser;
import javafx.stage.Stage;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.regex.Pattern;

public class Main extends Application {

    public static Parent root;

    @Override
    public void start(Stage primaryStage) throws Exception {
        root = FXMLLoader.load(getClass().getResource("sample.fxml"));
//        primaryStage.setTitle("Hello World");

        primaryStage.setResizable(false);
        primaryStage.setScene(new Scene(root));
        primaryStage.show();
    }


    public static void main(String[] args) {
        launch(args);
    }

    public Button openButton;
    public Button convertButton;
    public TextField widthTextField;
    public TextField heightTextField;
    public ImageView imageView;
    public CheckBox brailleCheckBox;
    public CheckBox ditheringCheckBox;
    public String currentImagePath;
    public javafx.scene.text.Text wrongSizesText;

    //---------------------------------------------------------------------------------------------------


    public boolean checkTextField(TextField textField, int maxValue)
    {
        String text = textField.getText();

        if (Pattern.matches("\\d{1,3}", text)) {
           if (Integer.parseInt(text) <= maxValue)  {
               return true;
           }
        }

        return false;
    }

    public void checkTextFields() {
        if (checkTextField(widthTextField, 255) && checkTextField(heightTextField, 255)) {
            convertButton.setDisable(false);
            wrongSizesText.setVisible(false);
        }
        else
        {
            convertButton.setDisable(true);
            wrongSizesText.setVisible(true);
        }
    }

    public void loadImage() {
        //Чекаем, существует ли такой файл, и не папка ли это. Чисто на всякий
        File file = new File(currentImagePath);
        if (file.exists() && !file.isDirectory()) {
            //Вся вот эта хуета нужна для отображения пикчи по размеру экранчика
            imageView.setPreserveRatio(false);
            Image imageViewImage = new Image("file:" + currentImagePath);
            double imageProportion = imageViewImage.getWidth() / imageViewImage.getHeight();
            double newWidth = imageView.getScene().getWindow().getWidth();
            double newHeight = newWidth / imageProportion;
            imageView.setFitWidth(newWidth);
            imageView.setFitHeight(newHeight);
            imageView.setImage(imageViewImage);
        }
    }

    public void open() {
        convertButton.setDisable(true);

        FileChooser fileChooser = new FileChooser();
        fileChooser.setTitle("Открыть файл");
        fileChooser.getExtensionFilters().addAll(
            new FileChooser.ExtensionFilter("Файлы изображений (JPG, PNG)", "*.jpg", "*.jpeg", "*.png")
        );
        File file = fileChooser.showOpenDialog(convertButton.getScene().getWindow());

        if (file != null) {
            convertButton.setDisable(false);

            currentImagePath = file.getPath();
            loadImage();
        }
    }

    public void save() throws IOException {
        FileChooser fileChooser = new FileChooser();
        fileChooser.setTitle("Сохранить файл");
        fileChooser.getExtensionFilters().addAll(
            new FileChooser.ExtensionFilter("Изображение OpenComputers", "*.pic")
        );
        File file = fileChooser.showSaveDialog(openButton.getScene().getWindow());

        if (file != null) {
            checkTextFields();
            convert(file.getPath());
        }
    }

    public class MyColor {
        int alpha;
        int red;
        int green;
        int blue;

        public MyColor(int argb) {
            this.alpha = 0xFF - (argb >> 24) & 0xFF;
            this.red = (argb >> 16) & 0xFF;
            this.green = (argb >> 8) & 0xFF;
            this.blue = argb & 0xFF;
        }

        public MyColor(int alpha, int red, int green, int blue) {
            this.alpha = alpha;
            this.red = red;
            this.green = green;
            this.blue = blue;
        }
    }

    public class MyPixel {
        MyColor background;
        MyColor foreground;
        int alpha;
        String symbol;

        public MyPixel(MyColor background, MyColor foreground, int alpha, String symbol) {
            this.background = background;
            this.foreground = foreground;
            this.alpha = alpha;
            this.symbol = symbol;
        }
    }

    public void writeMyPixel(FileOutputStream out, MyPixel myPixel) throws IOException {
        out.write((byte) myPixel.background.red);
        out.write((byte) myPixel.background.green);
        out.write((byte) myPixel.background.blue);
        out.write((byte) myPixel.foreground.red);
        out.write((byte) myPixel.foreground.green);
        out.write((byte) myPixel.foreground.blue);
        out.write((byte) myPixel.alpha);
        out.write(myPixel.symbol.getBytes(StandardCharsets.UTF_8));
    }

    public class MyImage
    {
        public int width;
        public int height;
        public MyColor[][] pixels;

        public MyImage(Image image)
        {
            this.width = (int) image.getWidth();
            this.height = (int) image.getHeight();
            this.pixels = new MyColor[this.height][this.width];

            for (int y = 0; y < this.height; y++) {
                for (int x = 0; x < this.width; x++) {
                    this.pixels[y][x] = new MyColor(image.getPixelReader().getArgb(x, y));
                }
            }
        }
    }


    //---------------------------------------------------------------------------------------------------


    public int[] palette = { 0x000000, 0x000040, 0x000080, 0x0000BF, 0x0000FF, 0x002400, 0x002440, 0x002480, 0x0024BF, 0x0024FF, 0x004900, 0x004940, 0x004980, 0x0049BF, 0x0049FF, 0x006D00, 0x006D40, 0x006D80, 0x006DBF, 0x006DFF, 0x009200, 0x009240, 0x009280, 0x0092BF, 0x0092FF, 0x00B600, 0x00B640, 0x00B680, 0x00B6BF, 0x00B6FF, 0x00DB00, 0x00DB40, 0x00DB80, 0x00DBBF, 0x00DBFF, 0x00FF00, 0x00FF40, 0x00FF80, 0x00FFBF, 0x00FFFF, 0x0F0F0F, 0x1E1E1E, 0x2D2D2D, 0x330000, 0x330040, 0x330080, 0x3300BF, 0x3300FF, 0x332400, 0x332440, 0x332480, 0x3324BF, 0x3324FF, 0x334900, 0x334940, 0x334980, 0x3349BF, 0x3349FF, 0x336D00, 0x336D40, 0x336D80, 0x336DBF, 0x336DFF, 0x339200, 0x339240, 0x339280, 0x3392BF, 0x3392FF, 0x33B600, 0x33B640, 0x33B680, 0x33B6BF, 0x33B6FF, 0x33DB00, 0x33DB40, 0x33DB80, 0x33DBBF, 0x33DBFF, 0x33FF00, 0x33FF40, 0x33FF80, 0x33FFBF, 0x33FFFF, 0x3C3C3C, 0x4B4B4B, 0x5A5A5A, 0x660000, 0x660040, 0x660080, 0x6600BF, 0x6600FF, 0x662400, 0x662440, 0x662480, 0x6624BF, 0x6624FF, 0x664900, 0x664940, 0x664980, 0x6649BF, 0x6649FF, 0x666D00, 0x666D40, 0x666D80, 0x666DBF, 0x666DFF, 0x669200, 0x669240, 0x669280, 0x6692BF, 0x6692FF, 0x66B600, 0x66B640, 0x66B680, 0x66B6BF, 0x66B6FF, 0x66DB00, 0x66DB40, 0x66DB80, 0x66DBBF, 0x66DBFF, 0x66FF00, 0x66FF40, 0x66FF80, 0x66FFBF, 0x66FFFF, 0x696969, 0x787878, 0x878787, 0x969696, 0x990000, 0x990040, 0x990080, 0x9900BF, 0x9900FF, 0x992400, 0x992440, 0x992480, 0x9924BF, 0x9924FF, 0x994900, 0x994940, 0x994980, 0x9949BF, 0x9949FF, 0x996D00, 0x996D40, 0x996D80, 0x996DBF, 0x996DFF, 0x999200, 0x999240, 0x999280, 0x9992BF, 0x9992FF, 0x99B600, 0x99B640, 0x99B680, 0x99B6BF, 0x99B6FF, 0x99DB00, 0x99DB40, 0x99DB80, 0x99DBBF, 0x99DBFF, 0x99FF00, 0x99FF40, 0x99FF80, 0x99FFBF, 0x99FFFF, 0xA5A5A5, 0xB4B4B4, 0xC3C3C3, 0xCC0000, 0xCC0040, 0xCC0080, 0xCC00BF, 0xCC00FF, 0xCC2400, 0xCC2440, 0xCC2480, 0xCC24BF, 0xCC24FF, 0xCC4900, 0xCC4940, 0xCC4980, 0xCC49BF, 0xCC49FF, 0xCC6D00, 0xCC6D40, 0xCC6D80, 0xCC6DBF, 0xCC6DFF, 0xCC9200, 0xCC9240, 0xCC9280, 0xCC92BF, 0xCC92FF, 0xCCB600, 0xCCB640, 0xCCB680, 0xCCB6BF, 0xCCB6FF, 0xCCDB00, 0xCCDB40, 0xCCDB80, 0xCCDBBF, 0xCCDBFF, 0xCCFF00, 0xCCFF40, 0xCCFF80, 0xCCFFBF, 0xCCFFFF, 0xD2D2D2, 0xE1E1E1, 0xF0F0F0, 0xFF0000, 0xFF0040, 0xFF0080, 0xFF00BF, 0xFF00FF, 0xFF2400, 0xFF2440, 0xFF2480, 0xFF24BF, 0xFF24FF, 0xFF4900, 0xFF4940, 0xFF4980, 0xFF49BF, 0xFF49FF, 0xFF6D00, 0xFF6D40, 0xFF6D80, 0xFF6DBF, 0xFF6DFF, 0xFF9200, 0xFF9240, 0xFF9280, 0xFF92BF, 0xFF92FF, 0xFFB600, 0xFFB640, 0xFFB680, 0xFFB6BF, 0xFFB6FF, 0xFFDB00, 0xFFDB40, 0xFFDB80, 0xFFDBBF, 0xFFDBFF, 0xFFFF00, 0xFFFF40, 0xFFFF80, 0xFFFFBF, 0xFFFFFF };

    public int getPaletteIndexFromColor(MyColor color)
    {
        int closestIndex = 0;
        double delta, closestDelta = 999999999.0d;
        MyColor paletteColor;

        for (int i = 0; i < palette.length; i++)
        {
            paletteColor = new MyColor(
                0x0,
                palette[i] >> 16,
                (palette[i] >> 8) & 0xFF,
                palette[i] & 0xFF
            );

            delta = Math.pow((double) (paletteColor.red - color.red), 2) +
                    Math.pow((double) (paletteColor.green - color.green), 2) +
                    Math.pow((double) (paletteColor.blue - color.blue), 2);

            if (delta < closestDelta)
            {
                closestDelta = delta;
                closestIndex = i;
            }
        }


        return closestIndex;
    }

    public MyColor getColorFromPaletteIndex(int paletteIndex)
    {
        return new MyColor(0xFF000000 | palette[paletteIndex]);
    }

    public MyColor getColorDifference(MyColor color1, MyColor color2)
    {
        return new MyColor(
            color1.alpha - color2.alpha,
            color1.red - color2.red,
            color1.green - color2.green,
            color1.blue - color2.blue
        );
    }

    public MyColor getAverageColor(MyColor color1, MyColor color2)
    {
        return new MyColor(
            (color1.alpha + color2.alpha) / 2,
            (color1.red + color2.red) / 2,
            (color1.green + color2.green) / 2,
            (color1.blue + color2.blue) / 2
        );
    }

    public MyColor colorSum(MyColor color1, MyColor color2)
    {
        return new MyColor(
            color1.alpha + color2.alpha,
            color1.red + color2.red,
            color1.green + color2.green,
            color1.blue + color2.blue
        );
    }

    public MyColor colorMultiply(MyColor color, double multiplyer)
    {
        return new MyColor(
            (int) (color.alpha * multiplyer),
            (int) (color.red * multiplyer),
            (int) (color.green * multiplyer),
            (int) (color.blue * multiplyer)
        );
    }

    public MyImage dither(MyImage myImage) {
        for (int y = 0; y < myImage.height; y++) {
            for (int x = 0; x < myImage.width; x++) {

                MyColor paletteColor = getColorFromPaletteIndex(getPaletteIndexFromColor(myImage.pixels[y][x]));
                MyColor colorDifference = getColorDifference(myImage.pixels[y][x], paletteColor);

                myImage.pixels[y][x] = paletteColor;

                if (x < myImage.width - 1) {
                    myImage.pixels[y][x + 1] = colorSum(
                        myImage.pixels[y][x + 1],
                        colorMultiply(colorDifference, 7.0d / 16.0d)
                    );

                    if (y < myImage.height - 1) {
                        myImage.pixels[y + 1][x + 1] = colorSum(
                            myImage.pixels[y + 1][x + 1],
                            colorMultiply(colorDifference, 1.0d / 16.0d)
                        );
                    }
                }

                if (y < myImage.height - 1) {
                    myImage.pixels[y + 1][x] = colorSum(
                        myImage.pixels[y + 1][x],
                        colorMultiply(colorDifference, 5.0d / 16.0d)
                    );

                    if (x > 0) {
                        myImage.pixels[y + 1][x - 1] = colorSum(
                            myImage.pixels[y + 1][x - 1],
                            colorMultiply(colorDifference, 3.0d / 16.0d)
                        );
                    }
                }
            }
        }

        return myImage;
    }

    //---------------------------------------------------------------------------------------------------


    public String getBrailleChar(int a, int b, int c, int d, int e, int f, int g, int h) {
        return Character.toString((char) (10240+128*h+64*g+32*f+16*d+8*b+4*e+2*c+a));
    }

    public MyColor[][] getBraiileArray(MyImage myImage, int fromX, int fromY) {
        MyColor[][] brailleArray = new MyColor[4][2];
        int imageX, imageY;

        for (int y = 0; y < 4; y++)
        {
            for (int x = 0; x < 2; x++)
            {
                imageX = fromX + x;
                imageY = fromY + y;

                if (imageX < myImage.width && imageY < myImage.height)
                {
                    brailleArray[y][x] = myImage.pixels[imageY][imageX];
                }
                else
                {
                    brailleArray[y][x] = new MyColor(0x00000000);
                }
            }
        }

        return brailleArray;
    }

    public double getColorDistance(MyColor myColor)
    {
        return Math.pow((double) myColor.red, 2) + Math.pow((double) myColor.green, 2) + Math.pow((double) myColor.blue, 2);
    }

    public double getChannelsDelta(MyColor color1, MyColor color2)
    {
        return Math.pow((double) color1.red - color2.red, 2) + Math.pow((double) color1.green - color2.green, 2) + Math.pow((double) color1.blue - color2.blue, 2);
    }

    public MyColor getBestMatch(MyColor color1, MyColor color2, MyColor targetColor)
    {
        return getChannelsDelta(color1, targetColor) < getChannelsDelta(color2, targetColor) ? color1 : color2;
    }

    public MyPixel getMyPixelFromMyImage(MyImage myImage, int fromX, int fromY)
    {
        MyColor[][] brailleArray = getBraiileArray(myImage, fromX, fromY);

        double distance, minDistance = 999999.0d, maxDistance = 0.0d;
        MyColor minColor = brailleArray[0][0], maxColor = brailleArray[0][0];

        for (int y = 0; y < 4; y++) {
            for (int x = 0; x < 2; x++)
            {
                distance = getColorDistance(brailleArray[y][x]);
                if (distance < minDistance)
                {
                    minDistance = distance;
                    minColor = brailleArray[y][x];
                }

                if (distance > maxDistance)
                {
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


        return new MyPixel(minColor, maxColor, 0x00, brailleChar);
    }

    //---------------------------------------------------------------------------------------------------

    public void convertAsSemiPixel(MyImage myImage, FileOutputStream out) throws IOException {
        MyColor upper, lower;

        for (int y = 0; y < myImage.height; y += 2) {
            for (int x = 0; x < myImage.width; x++) {

                upper = myImage.pixels[y][x];
                lower = myImage.pixels[y + 1][x];

                MyPixel myPixel = new MyPixel(upper, lower, 0x00, "#");

                if (upper.alpha == 0x00) {
                    //Есть и наверху, и внизу
                    if (lower.alpha == 0x00) {
                        myPixel.background = upper;
                        myPixel.foreground = lower;
                        myPixel.alpha = 0x00;
                        myPixel.symbol = "▄";
                    }
                    //Есть только наверху, внизу прозрачный
                    else {
                        myPixel.background = upper;
                        myPixel.foreground = upper;
                        myPixel.alpha = 0xFF;
                        myPixel.symbol = "▀";
                    }
                } else {
                    //Нет наверху, но есть внизу
                    if (lower.alpha == 0x00) {
                        myPixel.background = upper;
                        myPixel.foreground = lower;
                        myPixel.alpha = 0xFF;
                        myPixel.symbol = "▄";
                    }
                    //Нет ни наверху, ни внизу
                    else {
                        myPixel.background = upper;
                        myPixel.foreground = lower;
                        myPixel.alpha = 0xFF;
                        myPixel.symbol = " ";
                    }
                }

                writeMyPixel(out, myPixel);
            }
        }
    }

    public void convertAsBraiile(MyImage myImage, FileOutputStream out) throws IOException {
        for (int y = 0; y < myImage.height; y += 4)
        {
            for (int x = 0; x < myImage.width; x += 2)
            {
                writeMyPixel(out, getMyPixelFromMyImage(myImage, x, y));
            }
        }
    }

    public void convert(String path) throws IOException {
        FileOutputStream out = new FileOutputStream(path);

        //Сигнатурка и метод кодировки
        out.write("OCIF".getBytes(StandardCharsets.US_ASCII));
        out.write((byte) 0x1);

        double width, height;

        if (brailleCheckBox.isSelected())
        {
            width = Double.parseDouble(widthTextField.getText());
            height = Double.parseDouble(heightTextField.getText());

            out.write((byte) width);
            out.write((byte) height);

            MyImage myImage = new MyImage(new Image("file:" + currentImagePath, width * 2, height * 4, false, true));

            if (ditheringCheckBox.isSelected())
            {
                myImage = dither(myImage);
            }

            convertAsBraiile(myImage, out);
        }
        else
        {
            width = Double.parseDouble(widthTextField.getText());
            height = Double.parseDouble(heightTextField.getText());

            out.write((byte) width);
            out.write((byte) height);

            MyImage myImage = new MyImage(new Image("file:" + currentImagePath, width, height * 2, false, true));

            if (ditheringCheckBox.isSelected())
            {
                myImage = dither(myImage);
            }

            convertAsSemiPixel(myImage, out);
        }

        out.close();
    }
}
