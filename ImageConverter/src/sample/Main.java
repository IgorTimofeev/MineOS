package sample;

import javafx.animation.KeyFrame;
import javafx.animation.KeyValue;
import javafx.animation.Timeline;
import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.scene.control.Button;
import javafx.scene.control.TextField;
import javafx.scene.image.ImageView;
import javafx.scene.input.DragEvent;
import javafx.scene.input.Dragboard;
import javafx.scene.input.TransferMode;
import javafx.scene.layout.GridPane;
import javafx.scene.layout.Pane;
import javafx.scene.text.Text;
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

    public Button openButton;
    public Button convertButton;
    public TextField widthTextField;
    public TextField heightTextField;
    public ImageView imageView;
    public CheckBox brailleCheckBox;
    public CheckBox ditheringCheckBox;
    public Text wrongSizesText;
    public Text imageSizeText;
    public Slider ditheringSlider;
    public ComboBox<String> encodingMethodComboBox;
    public GridPane imageGridPane;
    public ImageView dragDropFilesImageView;
    public Pane settingsPane;
    public Pane mainPane;

    public GridPane hintsGridPane;
    public GridPane dragImageGridPane;
    public GridPane OCIFStringResutGridPane;
    public TextField OCIFStringResultTextField;
    public ImageView OCIFStringResultImageView;
    public GridPane OCIFStringResultGridPane;

    private String currentImagePath = "sample/Resources/Background.png";

    @Override
    public void start(Stage primaryStage) throws Exception {
        primaryStage.setResizable(false);
        primaryStage.setScene(new Scene(FXMLLoader.load(getClass().getResource("ImageConverter.fxml")), 840, 489));
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
                        // Масштаб пикчи и поля конвертации строки
                        new KeyValue(OCIFStringResultImageView.fitWidthProperty(), OCIFStringResultImageView.getImage().getWidth() * fromScale),
                        new KeyValue(OCIFStringResultGridPane.maxWidthProperty(), 312 * fromScale),
                        // Сдвигание хуйни с настройками
                        new KeyValue(settingsPane.layoutXProperty(), start ? mainPane.getWidth() - settingsPane.getWidth() : mainPane.getWidth())
                },
                new KeyValue[] {
                        new KeyValue(hintsGridPane.opacityProperty(), targetOpacity),
                        new KeyValue(dragDropFilesImageView.fitWidthProperty(),  dragDropFilesImageView.getImage().getWidth() * toScale),
                        new KeyValue(settingsPane.layoutXProperty(), start ? mainPane.getWidth() : mainPane.getWidth() - settingsPane.getWidth()),
                        // Масштаб пикчи и поля конвертации строки
                        new KeyValue(OCIFStringResultImageView.fitWidthProperty(), OCIFStringResultImageView.getImage().getWidth() * toScale),
                        new KeyValue(OCIFStringResultGridPane.maxWidthProperty(), 312 * toScale),
                }
        );

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
    }

    public void copyOCIFResultToClipboard() {
        Toolkit.getDefaultToolkit().getSystemClipboard().setContents(new StringSelection(OCIFStringResultTextField.getText()), null);
    }

    //Ебучий драг-дроп
    public void onHintsGridPaneDragEntered(DragEvent event) {
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
            File file = new File(dragboard.getFiles().get(0).getAbsolutePath());
            if (file.getAbsolutePath().toLowerCase().matches("^.+\\.(png)?(jpg)?(jpeg)?$")) {
                loadImage(file);
            }
        }

        dragImageGridPane.setVisible(false);
    }

    public void onHintsGridPaneDragMouseClicked() {
        if (hintsGridPane.getOpacity() == 1) {
            playAnimationEnd();
        }
    }

    public static void main(String[] args) {
        launch(args);
    }

    public void onDitheringStateChanged() {
        ditheringSlider.setDisable(!ditheringCheckBox.isSelected());
    }

    private boolean checkTextField(TextField textField) {
        if (Pattern.matches("\\d{1,3}", textField.getText())) {
            if (Integer.parseInt(textField.getText()) <= 255) {
                return true;
            }
        }

        return false;
    }

    public void onTextFieldTextChanged() {
        boolean state = (checkTextField(widthTextField) && checkTextField(heightTextField)) || encodingMethodComboBox.getValue().contains("OCIF5");

        imageSizeText.setVisible(state);
        wrongSizesText.setVisible(!state);
        convertButton.setDisable(!state);
    }

    private void loadImage(File file) {
        if (!file.isDirectory()) {
            currentImagePath = "file:" + file.getPath();

            javafx.scene.image.Image image = new javafx.scene.image.Image(currentImagePath);
            imageView.setImage(image);

            if (image.getWidth() >= image.getHeight()) {
                if (image.getWidth() <= imageGridPane.getWidth()) {
                    imageView.setFitWidth(image.getWidth());
                } else {
                    imageView.setFitWidth(imageGridPane.getWidth());
                }
            } else {
                double proportion = image.getWidth() / image.getHeight();

                if (image.getHeight() <= imageGridPane.getHeight()) {
                    imageView.setFitWidth(image.getHeight() * proportion);
                } else {
                    imageView.setFitWidth(imageGridPane.getWidth() * proportion);
                }
            }
        }
    }

    public void open() {
        FileChooser fileChooser = new FileChooser();
        fileChooser.setTitle("Открыть файл");
        fileChooser.getExtensionFilters().addAll(new FileChooser.ExtensionFilter("Файлы изображений (JPG, PNG)", "*.jpg", "*.jpeg", "*.png"));
        File file = fileChooser.showOpenDialog(convertButton.getScene().getWindow());

        if (file != null) {
            loadImage(file);
        }
    }

    public void save() throws IOException {
        if (encodingMethodComboBox.getValue().contains("OCIFString")) {
            String result = OCIF.convertToString(
                currentImagePath,
                Integer.parseInt(widthTextField.getText()),
                Integer.parseInt(heightTextField.getText()),
                brailleCheckBox.isSelected(),
                ditheringCheckBox.isSelected(),
                ditheringSlider.getValue()
            );

            dragImageGridPane.setVisible(false);
            OCIFStringResutGridPane.setVisible(true);
            playAnimationStart();

            OCIFStringResultTextField.setText(result);
        }
        else {
            FileChooser fileChooser = new FileChooser();
            fileChooser.setTitle("Сохранить файл");
            fileChooser.getExtensionFilters().addAll(new FileChooser.ExtensionFilter("Изображение OpenComputers", "*.pic"));
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
                        ditheringSlider.getValue()
                );
            }
        }
    }
}