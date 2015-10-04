using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ConsoleApplication
{
    class Program
    {
        static void Main(string[] args)
        {
            //Задаем стартовые константы - верхняя граница, нижняя граница, шаг итерации функции, значение самой функции
            double upperBorder, lowerBorder, increment, functionValue, argumentValue;
            
            //Запрашиваем значение переменных через консоль
            Console.WriteLine(" ");
            Console.WriteLine("Введите нижнюю границу отрезка:");
            lowerBorder = Convert.ToDouble(Console.ReadLine());

            Console.WriteLine(" ");
            Console.WriteLine("Введите верхнюю границу отрезка:");
            upperBorder = Convert.ToDouble(Console.ReadLine());
            
            Console.WriteLine(" ");
            Console.WriteLine("Введите шаг табуляции функции:");
            increment = Convert.ToDouble(Console.ReadLine());

            Console.WriteLine(" ");

            //Задаем стартовое значение аргумента функции, эквивалентное нижней границе отрезка
            argumentValue = lowerBorder;
            
            //При помощи цикла выводим на экран значения функции при варьирующемся аргументе в зависимости от указанного инкремента
            while (argumentValue <= upperBorder) {
               
                //Смотрим на значение аргумента функции и выбираем нужную формулу расчета функции в зависимости от условий задачи
                if (Math.Abs(argumentValue) < 2)
                {
                    //Считаем значение функции
                    functionValue = Math.Pow(Math.Sin(5 * argumentValue), 3);

                    //Выводим на экран значение функции при текущем аргументе
                    Console.WriteLine("f(" + argumentValue + ") = Math.Pow(Math.Sin(5 * " + argumentValue + "), 3) = " + functionValue);
                }
                else
                {
                    functionValue = Math.Exp(2 * argumentValue);
                    Console.WriteLine("f(" + argumentValue + ") = Math.Exp(2 * " + argumentValue + ") = " + functionValue);
                } 
        
                //Прибавляем к значению аргумента значение инкремента
                argumentValue = argumentValue + increment;
            }

            //Ожидаем нажатия клавиши. Костыль, но работает
            Console.ReadKey();
        }
    }
}