package sample;


public class Pixel {
    Color background;
    Color foreground;
    int alpha;
    String symbol;

    public Pixel(Color background, Color foreground, int alpha, String symbol) {
        this.background = background;
        this.foreground = foreground;
        this.alpha = alpha;
        this.symbol = symbol;
    }
}