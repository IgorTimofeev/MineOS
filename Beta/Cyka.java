package com.dreamfinity.main.api;

import net.minecraft.client.Minecraft;
import net.minecraft.util.ResourceLocation;
import org.lwjgl.input.Mouse;

import java.awt.*;

/**
 * Created by Pirnogion on 19.01.2016.
 * SOSI, CYKA
 * REKOSTILED BY IGOR
 */

public class MineButton extends DreamAPI
{

    private Minecraft mc = DreamAPI.mc;

    public boolean isHover = false;
    public boolean isPressed = false;
    public boolean visible = true;
    public Runnable callback;
    public int x = 1;
    public int y = 1;
    public int width = 10;
    public int height = 20;
    public String text = "";
    public ButtonStyle style;
    private float textSize = 3;

    //Класс стиля кнопки
    public class ButtonStyle {
        public class Standard {
            public Color buttonColor;
            public Color textColor;
            public ResourceLocation texture;
        }

        public class Hovered {
            public Color buttonColor;
            public Color textColor;
            public ResourceLocation texture;
        }

        public class Pressed {
            public Color buttonColor;
            public Color textColor;
            public ResourceLocation texture;
        }

        public Standard standard = new Standard();
        public Hovered hovered = new Hovered();
        public Pressed pressed = new Pressed();
        public String type;

        public ButtonStyle(int buttonColor, int buttonHoverColor, int buttonPressColor, int textColor, int textHoverColor, int textPressColor) {
            this.standard.buttonColor = new Color(buttonColor);
            this.hovered.buttonColor = new Color(buttonHoverColor);
            this.pressed.buttonColor = new Color(buttonPressColor);

            this.standard.textColor = new Color(textColor);
            this.hovered.textColor = new Color(textHoverColor);
            this.pressed.textColor = new Color(textPressColor);

            this.type = "flat";
        }

        public ButtonStyle(ResourceLocation buttonTexture, ResourceLocation buttonHoverTexture, ResourceLocation buttonPressTexture, int textColor, int textHoverColor, int textPressColor) {
            this.standard.texture = buttonTexture;
            this.hovered.texture = buttonHoverTexture;
            this.pressed.texture = buttonPressTexture;

            this.standard.textColor = new Color(textColor);
            this.hovered.textColor = new Color(textHoverColor);
            this.pressed.textColor = new Color(textPressColor);

            this.type = "textured";
        }

        public ButtonStyle() {
            this.standard.buttonColor = new Color(0x00A8FF);
            this.hovered.buttonColor = new Color(0x42A8ff);
            this.pressed.buttonColor = new Color(0xFFFFFF);

            this.standard.textColor = new Color(0xFFFFFF);
            this.hovered.textColor = new Color(0xFFFFFF);
            this.pressed.textColor = new Color(0x555555);

            this.type = "flat";
        }
    }

    //Конструктор кнопки без аргументов (по умолчанию во флет-дизайне)
    public MineButton()
    {
        this.style = new ButtonStyle();
        this.callback = () -> System.out.println("Тест!");
        this.isPressed = false;
        this.isHover = false;
        this.x = 1;
        this.y = 1;
        this.width = 200;
        this.height = 50;
        this.text = "Button";
    }

    //Функция для отрисовки текста с определенным цветом
    //Костыльно, зато удобно
    private void drawText(Color textColor) {
        drawScaledString(this.text, this.x + this.width / 2,this.y + this.height / 2 - (this.textSize * 4), textSize, TextPosition.CENTER);
        //this.drawCenteredString(this.mc.fontRenderer, this.text, this.x + this.width / 2, this.y + (this.height - 8) / 2, RGBtoHEX(textColor));
    }

    //Функция отрисовки
    public void draw(int x, int y)
    {
        //Eсли кнопка невидимая, то отменить отрисовку
        if (!visible) {
            return;
        }

        //Отрисовка
        //Если кликнуто
        if ( this.isPressed )
        {
            //Рисуем в зависимости от стиля кнопки
            if ( this.style.type == "flat" )
            {
                int padding = (int) (0.1f * this.height);
                square(this.x, this.y, this.width, this.height - padding, this.style.pressed.buttonColor);
                square(this.x, this.y + this.height - padding, this.width, padding, alphaBlend(this.style.pressed.buttonColor, Color.black, 180));
            }
            else
            {

            }

            //Рисуем текст
            drawText(this.style.pressed.textColor);
        }
        //Если просто наведено мышкой
        else if ( isHover )
        {
            //Рисуем в зависимости от стиля кнопки
            if ( this.style.type == "flat" )
            {
                int padding = (int) (0.1f * this.height);
                square(this.x, this.y, this.width, this.height - padding, this.style.hovered.buttonColor);
                square(this.x, this.y + this.height - padding, this.width, padding, alphaBlend(this.style.hovered.buttonColor, Color.black, 180));
            }
            else
            {

            }

            //Рисуем текст
            drawText(this.style.hovered.textColor);
        }
        //Если ни то, ни другое - т.е. обычное состояние кнопки
        else
        {
            //Рисуем в зависимости от стиля кнопки
            if ( this.style.type == "flat" )
            {
                int padding = (int) (0.1f * this.height);
                square(this.x, this.y, this.width, this.height - padding, this.style.standard.buttonColor);
                square(this.x, this.y + this.height - padding, this.width, padding, alphaBlend(this.style.standard.buttonColor, Color.black, 180));
            }
            else
            {

            }

            //Рисуем текст
            drawText(this.style.standard.textColor);
        }
    }

    //Обработка
    boolean prevState;
    public MineButton update(int x, int y) {
        x = x * getScaleFactor();
        y = y * getScaleFactor();
        isHover = x >= this.x && y >= this.y && x < this.x + this.width && y < this.y + this.height;

        if (!visible) return this;
        boolean released = !Mouse.getEventButtonState();


        if (isHover && Mouse.isButtonDown(0) && !prevState) {
            if (!isPressed) {
                callback.run();
            }
            isPressed = true;
        } else {
            isPressed = false;
        }
        prevState = Mouse.isButtonDown(0);

        //Отрисовываем
        this.draw(x, y);

        return this;
    }

    //Стиль кнопки во флет-дизайне
    public void setStyle(int buttonColor, int buttonHoverColor, int buttonPressColor, int textColor, int textHoverColor, int textPressColor)
    {
        this.style.type = "flat";
        this.style = new ButtonStyle(buttonColor, buttonHoverColor, buttonPressColor, textColor, textHoverColor, textPressColor);
    }

    //Стиль кнопки в текстурном дизайне
    public void setStyle(String buttonTexture, String buttonTextureHover, String buttonTexturePress, int textColor, int textHoverColor, int textPressColor)
    {
        this.style.type = "textured";
        this.style = new ButtonStyle(
                new ResourceLocation(buttonTexture),
                new ResourceLocation(buttonTextureHover),
                new ResourceLocation(buttonTexturePress),
                textColor,
                textHoverColor,
                textPressColor
        );
    }

    //Установить размер текста
    public void setTextSize(float textSize)
    {
        this.textSize = textSize;
    }

    //Изменить размер кнопки
    public void setSize(int width, int height)
    {
        this.width = width;
        this.height = height;
    }

    //Изменить расположение кнопки
    public void setPosition(int x, int y)
    {
        this.x = x;
        this.y = y;
    }

    //Изменить текст кнопки
    public void setText(String text)
    {
        this.text = text;
    }

    //Установить функцию, выполняемую при нажатии на кнопку
    public void setCallback(Runnable callback)
    {
        this.callback = callback;
    }

    //Установить цвет текста
    public void setTextColor(int textColor, int textHoverColor, int textPressColor)
    {
        this.style.standard.textColor = new Color(textColor);
        this.style.hovered.textColor = new Color(textHoverColor);
        this.style.pressed.textColor = new Color(textPressColor);
    }

    //Установить цвет кнопки для всех стилей одинаково без ебли мозга
    public void setTextColor(int color)
    {
        Color cyka = new Color(color);
        this.style.standard.textColor = cyka;
        this.style.hovered.textColor = cyka;
        this.style.pressed.textColor = cyka;
    }

    //Установить цвет кнопки по всем трем стилям
    public void setButtonColor(int buttonColor, int buttonHoverColor, int buttonPressColor)
    {
        this.style.standard.buttonColor = new Color(buttonColor);
        this.style.hovered.buttonColor = new Color(buttonHoverColor);
        this.style.pressed.buttonColor = new Color(buttonPressColor);
    }

    //Установить цвет кнопки для всех стилей одинаково без ебли мозга
    public void setButtonColor(int color)
    {
        Color cyka = new Color(color);
        this.style.standard.buttonColor = cyka;
        this.style.hovered.buttonColor = cyka;
        this.style.pressed.buttonColor = cyka;
    }
}
