package sample;

import javafx.animation.KeyFrame;
import javafx.animation.KeyValue;
import javafx.animation.Timeline;
import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.scene.image.ImageView;
import javafx.scene.input.Dragboard;
import javafx.scene.input.TransferMode;
import javafx.scene.layout.GridPane;
import javafx.scene.layout.Pane;
import javafx.scene.text.Text;
import javafx.stage.FileChooser;
import javafx.stage.Stage;
import javafx.util.Callback;
import javafx.util.Duration;

import java.io.File;
import java.io.IOException;
import java.util.regex.Pattern;

public class Main extends Application {

    public static Parent root;
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
    public String currentImagePath = "sample/Resources/Background.png";
    public Pane dragDropPane;
    public GridPane gridPane;

    @Override
    public void start(Stage primaryStage) throws Exception {
        root = FXMLLoader.load(getClass().getResource("ImageConverter.fxml"));
        primaryStage.setResizable(false);
        Scene scene = new Scene(root);
        primaryStage.setScene(scene);
        primaryStage.show();
    }

    private void playAnimation(boolean start)
    {
        Timeline timeline = new Timeline();
        timeline.getKeyFrames().addAll(
                new KeyFrame(
                        new Duration(0),
                        new KeyValue(dragDropPane.opacityProperty(), start ? 0.0 : 1.0)
                ),
                new KeyFrame(
                        new Duration(250),
                        new KeyValue(dragDropPane.opacityProperty(), start ? 1.0 : 0.0)
                )
        );

        timeline.play();
    }

    public void initialize() {
        // Пидорасим текст по центру комбобокса
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

        // А это уже в выпадающем списке
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

        //Ебучий драг-дроп
        dragDropPane.setOnDragEntered(event -> {
            if (event.getDragboard().hasFiles()) {
                playAnimation(true);
                event.acceptTransferModes(TransferMode.COPY);
            }
        });

        dragDropPane.setOnDragExited(event -> {
            playAnimation(false);

            Dragboard dragboard = event.getDragboard();
            if (dragboard.hasFiles()) {
                File file = new File(dragboard.getFiles().get(0).getAbsolutePath());
                if (file.getAbsolutePath().matches("^.+\\.(png)?(jpg)?(jpeg)?$")) {
                    loadImage(file);
                }
            }
        });
    }

    public static void main(String[] args) {
        launch(args);
    }

    public void onDitheringStateChanged() {
        ditheringSlider.setDisable(!ditheringCheckBox.isSelected());
    }

    private boolean checkTextField(TextField textField, int maxValue) {
        if (Pattern.matches("\\d{1,3}", textField.getText())) {
            if (Integer.parseInt(textField.getText()) <= maxValue) {
                return true;
            }
        }

        return false;
    }

    public void onTextFieldTextChanged() {
        boolean state = checkTextField(widthTextField, 255) && checkTextField(heightTextField, 255);

        convertButton.setDisable(!state);
        imageSizeText.setVisible(state);
        wrongSizesText.setVisible(!state);
    }

    public void loadImage(File file) {
        if (!file.isDirectory()) {
            currentImagePath = "file:" + file.getPath();

            javafx.scene.image.Image image = new javafx.scene.image.Image(currentImagePath);
            imageView.setImage(image);

            if (image.getWidth() >= image.getHeight()) {
                if (image.getWidth() <= gridPane.getWidth()) {
                    imageView.setFitWidth(image.getWidth());
                } else {
                    imageView.setFitWidth(gridPane.getWidth());
                }
            } else {
                double proportion = image.getWidth() / image.getHeight();

                if (image.getHeight() <= gridPane.getHeight()) {
                    imageView.setFitWidth(image.getHeight() * proportion);
                } else {
                    imageView.setFitWidth(gridPane.getWidth() * proportion);
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
                    encodingMethodComboBox.getValue().equals("OCIF6") ? 6 : 1,
                    brailleCheckBox.isSelected(),
                    ditheringCheckBox.isSelected(),
                    ditheringSlider.getValue()
            );
        }
    }
}