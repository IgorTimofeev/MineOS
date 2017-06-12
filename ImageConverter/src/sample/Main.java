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
    public Pane dragDropAnimationGridPane;
    public GridPane imageGridPane;
    public ImageView dragDropFilesImageView;
    public Pane settingsPane;
    public Pane mainPane;

    private String currentImagePath = "sample/Resources/Background.png";

    @Override
    public void start(Stage primaryStage) throws Exception {
        primaryStage.setResizable(false);
        Scene scene = new Scene(FXMLLoader.load(getClass().getResource("ImageConverter.fxml")));
        primaryStage.setScene(scene);
        primaryStage.show();
    }

    private Timeline newTimeLine(int duration, KeyValue[] startKeyValues, KeyValue[] endKeyValues) {
        Timeline timeline = new Timeline();

        timeline.getKeyFrames().add(new KeyFrame(new Duration(0), startKeyValues));
        timeline.getKeyFrames().add(new KeyFrame(new Duration(duration), endKeyValues));

        return timeline;
    }

    private void playDragDropFileAnimation(boolean start, boolean moveSettingsPane, double targetOpacity, double fromScale, double toScale)
    {
        Timeline timeline = newTimeLine(
                150,
                new KeyValue[] {
                        new KeyValue(dragDropAnimationGridPane.opacityProperty(), dragDropAnimationGridPane.getOpacity()),
                        new KeyValue(dragDropFilesImageView.fitWidthProperty(), dragDropFilesImageView.getImage().getWidth() * fromScale),
                        moveSettingsPane ? new KeyValue(settingsPane.layoutXProperty(), start ? mainPane.getWidth() - settingsPane.getWidth() : mainPane.getWidth()) : null
                },
                new KeyValue[] {
                        new KeyValue(dragDropAnimationGridPane.opacityProperty(), targetOpacity),
                        new KeyValue(dragDropFilesImageView.fitWidthProperty(),  dragDropFilesImageView.getImage().getWidth() * toScale),
                        moveSettingsPane ? new KeyValue(settingsPane.layoutXProperty(), start ? mainPane.getWidth() : mainPane.getWidth() - settingsPane.getWidth()) : null
                }
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
        dragDropAnimationGridPane.setOnDragEntered(event -> {
            if (event.getDragboard().hasFiles()) {
                playDragDropFileAnimation(true, true,1.0d, 0.8d, 1.0d);
                event.acceptTransferModes(TransferMode.COPY);
            }
        });

        dragDropAnimationGridPane.setOnDragExited(event -> {
            playDragDropFileAnimation(false, true, 0.0d, 1.0d, 0.8d);

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

    private boolean checkTextField(TextField textField) {
        if (Pattern.matches("\\d{1,3}", textField.getText())) {
            if (Integer.parseInt(textField.getText()) <= 255) {
                return true;
            }
        }

        return false;
    }

    public void onTextFieldTextChanged() {
        boolean state = checkTextField(widthTextField) && checkTextField(heightTextField);

        convertButton.setDisable(!state);
        imageSizeText.setVisible(state);
        wrongSizesText.setVisible(!state);
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