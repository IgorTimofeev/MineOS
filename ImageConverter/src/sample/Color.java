package sample;


public class Color {
    int alpha;
    int red;
    int green;
    int blue;

    public Color(int argb) {
        this.alpha = 0xFF - (argb >> 24) & 0xFF;
        this.red = (argb >> 16) & 0xFF;
        this.green = (argb >> 8) & 0xFF;
        this.blue = argb & 0xFF;
    }

    public Color(int alpha, int red, int green, int blue) {
        this.alpha = alpha;
        this.red = red;
        this.green = green;
        this.blue = blue;
    }

    public int toArgb()
    {
        return (this.alpha << 24) | ((this.red << 16) | ((this.green << 8) | this.blue));
    }

    public static Color difference(Color color1, Color color2)
    {
        return new Color(
                color1.alpha - color2.alpha,
                color1.red - color2.red,
                color1.green - color2.green,
                color1.blue - color2.blue
        );
    }

    public static Color sum(Color color1, Color color2)
    {
        int aSum = color1.alpha + color2.alpha;
        int rSum = color1.red + color2.red;
        int gSum = color1.green + color2.green;
        int bSum = color1.blue + color2.blue;

        if (aSum > 255) aSum = 255;
        if (rSum > 255) rSum = 255;
        if (gSum > 255) gSum = 255;
        if (bSum > 255) bSum = 255;

        return new Color(aSum, rSum, gSum, bSum);
    }

    public static Color average(Color color1, Color color2) {
        return new Color(
            (color1.alpha + color2.alpha) / 2,
            (color1.red + color2.red) / 2,
            (color1.green + color2.green) / 2,
            (color1.blue + color2.blue) / 2
        );
    }

    public static Color multiply(Color color, double multiplyer)
    {
        return new Color(
                (int) (color.alpha * multiplyer),
                (int) (color.red * multiplyer),
                (int) (color.green * multiplyer),
                (int) (color.blue * multiplyer)
        );
    }
}