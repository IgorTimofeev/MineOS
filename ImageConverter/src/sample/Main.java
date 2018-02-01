package sample;

import javafx.animation.KeyFrame;
import javafx.animation.KeyValue;
import javafx.animation.Timeline;
import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.*;
import javafx.scene.control.Label;
import javafx.scene.control.TextField;
import javafx.scene.image.ImageView;
import javafx.scene.input.*;
import javafx.scene.layout.GridPane;
import javafx.scene.layout.Pane;
import javafx.scene.paint.Color;
import javafx.stage.FileChooser;
import javafx.stage.Stage;
import javafx.util.Callback;
import javafx.util.Duration;

import java.awt.*;
import java.awt.datatransfer.StringSelection;
import java.io.File;
import java.io.IOException;
import java.util.regex.Pattern;

public class Main extends Application {

    public GridPane mainPane;

    public CheckBox keepProportionsCheckBox;
    public Button openButton;
    public Button convertButton;
    public TextField widthTextField;
    public TextField heightTextField;
    public ImageView imageView;
    public CheckBox brailleCheckBox;
    public Label imageSizeInfoLabel;
    public ComboBox<String> encodingMethodComboBox;
    public ImageView dragDropFilesImageView;
    public GridPane settingsPane;

    public GridPane hintsGridPane;
    public GridPane dragImageGridPane;
    public GridPane OCIFStringResutGridPane;
    public TextField OCIFStringResultTextField;
    public ImageView OCIFStringResultImageView;
    public GridPane OCIFStringResultGridPane;

    public CheckBox ditheringCheckBox;
    public GridPane ditheringMainPane;
    public Label ditheringOpacityLabel;
    public Pane ditheringBackgroundPane;
    public Slider ditheringOpacitySlider;

    private String currentImagePath = "sample/Resources/Background.png";

    @Override
    public void start(Stage primaryStage) throws Exception {
        primaryStage.setScene(new Scene(FXMLLoader.load(getClass().getResource("ImageConverter.fxml"))));
        primaryStage.show();
    }

    private Timeline newTimeLine(int duration, KeyValue[] startKeyValues, KeyValue[] endKeyValues) {
        Timeline timeline = new Timeline();

        timeline.getKeyFrames().add(new KeyFrame(new Duration(0), startKeyValues));
        timeline.getKeyFrames().add(new KeyFrame(new Duration(duration), endKeyValues));

        return timeline;
    }

    private void playAnimation(boolean start, double targetOpacity, double fromScale, double toScale) {
        Timeline timeline = newTimeLine(
            150,
            new KeyValue[] {
                // Прозрачность ебалы
                new KeyValue(hintsGridPane.opacityProperty(), hintsGridPane.getOpacity()),
                // Масштаб пикчи с драг дропом
                new KeyValue(dragDropFilesImageView.fitWidthProperty(), dragDropFilesImageView.getImage().getWidth() * fromScale),
                // Сдвигание хуйни с настройками
                new KeyValue(settingsPane.prefWidthProperty(), start ? 250 : 0),
                // Масштаб пикчи и поля конвертации строки
                new KeyValue(OCIFStringResultImageView.fitWidthProperty(), OCIFStringResultImageView.getImage().getWidth() * fromScale),
                new KeyValue(OCIFStringResultGridPane.maxWidthProperty(), 312 * fromScale)
            },
            new KeyValue[] {
                new KeyValue(hintsGridPane.opacityProperty(), targetOpacity),
                new KeyValue(dragDropFilesImageView.fitWidthProperty(),  dragDropFilesImageView.getImage().getWidth() * toScale),
                new KeyValue(settingsPane.prefWidthProperty(), start ? 0 : 250),
                // Масштаб пикчи и поля конвертации строки
                new KeyValue(OCIFStringResultImageView.fitWidthProperty(), OCIFStringResultImageView.getImage().getWidth() * toScale),
                new KeyValue(OCIFStringResultGridPane.maxWidthProperty(), 312 * toScale),
            }
        );

        timeline.setOnFinished(event -> {
            if (!start) {
                hintsGridPane.setVisible(false);
            }
        });

        timeline.play();
    }

    private void playAnimationStart() {
        playAnimation(true, 1.0d, 0.8d, 1.0d);
    }

    private void playAnimationEnd() {
        playAnimation(false, 0.0d, 1.0d, 0.8d);
    }

    public void initialize() {
        // Центрируем хуйню самого комбобокса
        encodingMethodComboBox.setButtonCell(new ListCell<String>() {
            @Override
            public void updateItem(String item, boolean empty) {
                super.updateItem(item, empty);
                if (item != null) {
                    setText(item);
                    setAlignment(Pos.CENTER);
                    Insets old = getPadding();
                    setPadding(new Insets(old.getTop(), 0, old.getBottom(), 32));
                }
            }
        });

        // Центрируем хуйню в выпадающем списке комбобокса
        encodingMethodComboBox.setCellFactory(new Callback<ListView<String>, ListCell<String>>() {
            @Override
            public ListCell<String> call(ListView<String> list) {
                return new ListCell<String>() {
                    @Override
                    public void updateItem(String item, boolean empty) {
                        super.updateItem(item, empty);
                        if (item != null) {
                            setText(item);
                            setAlignment(Pos.CENTER);
                        }
                    }
                };
            }
        });

        encodingMethodComboBox.setValue("OCIF6 (Optimized)");
        onTextFieldTextChanged();
    }

    public void copyOCIFResultToClipboard() {
        Toolkit.getDefaultToolkit().getSystemClipboard().setContents(new StringSelection(OCIFStringResultTextField.getText()), null);
    }

    //Ебучий драг-дроп
    public void onHintsGridPaneDragEntered(DragEvent event) {
        hintsGridPane.setVisible(true);
        dragImageGridPane.setVisible(true);
        OCIFStringResutGridPane.setVisible(false);

        if (event.getDragboard().hasFiles()) {
            playAnimationStart();
            event.acceptTransferModes(TransferMode.COPY);
        }
    }

    public void onHintsGridPaneDragExited(DragEvent event) {
        playAnimationEnd();

        Dragboard dragboard = event.getDragboard();
        if (dragboard.hasFiles()) {
            File file = dragboard.getFiles().get(0);
            if (file.getAbsolutePath().toLowerCase().matches("^.+\\.(png)?(jpg)?(jpeg)?$")) {
                loadImage(file);
            }
        }
    }

    public void onHintsGridPaneDragMouseClicked() {
        if (hintsGridPane.isVisible()) {
            playAnimationEnd();
        }
    }

    public static void main(String[] args) {
        launch(args);
    }

    public void onDitheringStateChanged() {
        boolean state = ditheringCheckBox.isSelected();

        Timeline timeline = newTimeLine(
                150,
                new KeyValue[] {
                        new KeyValue(ditheringBackgroundPane.opacityProperty(), state ? 0 : 1),
                        new KeyValue(ditheringMainPane.prefHeightProperty(), state ? 38 : 120),
                        new KeyValue(ditheringOpacitySlider.layoutYProperty(), state ? 38 : 65),
                        new KeyValue(ditheringOpacityLabel.layoutYProperty(), state ? 38 : 45)

                },
                new KeyValue[] {
                        new KeyValue(ditheringBackgroundPane.opacityProperty(), state ? 1 : 0),
                        new KeyValue(ditheringMainPane.prefHeightProperty(), state ? 120 : 38),
                        new KeyValue(ditheringOpacitySlider.layoutYProperty(), state ? 65 : 38),
                        new KeyValue(ditheringOpacityLabel.layoutYProperty(), state ? 45 : 38)
                }
        );

        timeline.setOnFinished(event -> ditheringOpacitySlider.setDisable(!state));

        timeline.play();

    }

    private boolean checkTextField(TextField textField) {
        return Pattern.matches("\\d+", textField.getText());
    }

    private void checkToCalculateHeight() {
        if (keepProportionsCheckBox.isSelected()) {
            double width = Double.parseDouble(widthTextField.getText());
            double imageProportion = imageView.getImage().getWidth() / imageView.getImage().getHeight();
            double height = width / imageProportion / 2;

            heightTextField.setText(Integer.toString((int) Math.round(height)));
        }
    }

    public void onProportionsCheckBoxClicked() {
        heightTextField.setDisable(keepProportionsCheckBox.isSelected());
        checkToCalculateHeight();
    }

    public void onTextFieldTextChanged() {
        boolean textFieldsOK = checkTextField(widthTextField) && checkTextField(heightTextField);

        if (textFieldsOK) {
            checkToCalculateHeight();
        }

        boolean sizesOK = (textFieldsOK && Integer.parseInt(widthTextField.getText()) <= 255 && Integer.parseInt(heightTextField.getText()) <= 255) || encodingMethodComboBox.getValue().contains("OCIF5");
        boolean allOK = sizesOK && textFieldsOK;

        imageSizeInfoLabel.setTextFill(allOK ? Color.color(1, 1, 1) : Color.color(1,0.2431,0.2549));
        imageSizeInfoLabel.setText(sizesOK ? "Output size for OpenComputers" : (textFieldsOK ? "Size > 255 is only supported by OCIF5 format" : "What the fuck did you write here?"));

        convertButton.setDisable(!allOK);
    }


    private double xDrag = 0, yDrag = 0;
    public void onImageDrag(MouseEvent mouseEvent) {
        double x = mouseEvent.getScreenX(), y = mouseEvent.getScreenY();

        imageView.setLayoutX(imageView.getLayoutX() + (x - xDrag));
        imageView.setLayoutY(imageView.getLayoutY() + (y - yDrag));

        xDrag = x;
        yDrag = y;
    }

    public void onImageClick(MouseEvent mouseEvent) {
        xDrag = mouseEvent.getScreenX();
        yDrag = mouseEvent.getScreenY();
    }

    public void onImageScroll(ScrollEvent scrollEvent) {
        double percentage = 0.15;
        double newWidth = imageView.getFitWidth() * (1 + (scrollEvent.getDeltaY() > 0 ? percentage : -percentage));
        double newHeight = newWidth * (imageView.getImage().getWidth() / imageView.getImage().getHeight());

        Timeline timeline = newTimeLine(
            100,
            new KeyValue[] {
                new KeyValue(imageView.fitWidthProperty(), imageView.getFitWidth()),
                new KeyValue(imageView.fitHeightProperty(), imageView.getFitHeight())
            },
            new KeyValue[] {
                new KeyValue(imageView.fitWidthProperty(), newWidth),
                new KeyValue(imageView.fitHeightProperty(), newHeight)
            }
        );

        timeline.play();
    }

    private void loadImage(File file) {
        if (!file.isDirectory()) {
            currentImagePath = "file:" + file.getPath();

            javafx.scene.image.Image image = new javafx.scene.image.Image(currentImagePath);
            imageView.setImage(image);
            checkToCalculateHeight();
        }
    }

    public void open() {
        FileChooser fileChooser = new FileChooser();
        fileChooser.setTitle("Open file");
        fileChooser.getExtensionFilters().addAll(new FileChooser.ExtensionFilter("Images (JPG, PNG)", "*.jpg", "*.jpeg", "*.png"));
        File file = fileChooser.showOpenDialog(convertButton.getScene().getWindow());

        if (file != null) {
            loadImage(file);
        }
    }

    public void save() throws IOException {
        if (encodingMethodComboBox.getValue().contains("OCIFString")) {
            OCIFStringResultTextField.setText(OCIF.convertToString(
                    currentImagePath,
                    Integer.parseInt(widthTextField.getText()),
                    Integer.parseInt(heightTextField.getText()),
                    brailleCheckBox.isSelected(),
                    ditheringCheckBox.isSelected(),
                    ditheringOpacitySlider.getValue() / 100.0d
            ));

            hintsGridPane.setVisible(true);
            dragImageGridPane.setVisible(false);
            OCIFStringResutGridPane.setVisible(true);
            playAnimationStart();
        }
        else {
            FileChooser fileChooser = new FileChooser();
            fileChooser.setTitle("Save file");
            fileChooser.getExtensionFilters().addAll(new FileChooser.ExtensionFilter("OpenComputers image", "*.pic"));
            File file = fileChooser.showSaveDialog(openButton.getScene().getWindow());

            if (file != null) {
                OCIF.convert(
                    currentImagePath,
                    file.getPath(),
                    Integer.parseInt(widthTextField.getText()),
                    Integer.parseInt(heightTextField.getText()),
                    encodingMethodComboBox.getValue().contains("OCIF6") ? 6 : 5,
                    brailleCheckBox.isSelected(),
                    ditheringCheckBox.isSelected(),
                    ditheringOpacitySlider.getValue() / 100.0d
                );
            }
        }
    }
}