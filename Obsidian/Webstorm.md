# Установка WebStorm на MacOS

[Источник](https://blog.llinh9ra.ru/%D1%81%D0%BE%D1%84%D1%82/%D0%B0%D0%BA%D1%82%D0%B8%D0%B2%D0%B0%D1%86%D0%B8%D1%8F-phpstorm-webstorm-intellij-idea-%D0%B8-%D0%B4%D1%80%D1%83%D0%B3%D0%B8%D0%B5-%D0%BF%D1%80%D0%BE%D0%B4%D1%83%D0%BA%D1%82%D1%8B-jetbrains-%D0%B2/comment-page-2/)

1. Зайти на доступное [зеркало](https://3.jetbra.in/) проверить актуальную для прошивки версию
2. Установить [лицензию WebStorm](https://www.jetbrains.com/ru-ru/webstorm/download/) совместимой версии
3. Скачать `jetbra.zip` архив с [зеркала](https://3.jetbra.in/)
4. Перейти в корень установленного `WebStorm`:

```
# 1 вариант:
Finder -> Applications -> на иконке WebStorm открыть контекстное меню и выбрать "Show package content" -> Contents

# 2 вариант:
Terminal -> open /Applications/WebStorm.app/Contents

```

5. Из папки `jetbra/vmoptions` скопировать два конфига `jetbrains_client.vmoptions` и `webstorm.vmoptions` , затем в папке `Contents/bin` их вставить и заменить оригинальные
6. Так же в папку `Contents/bin` скопировать `jetbra/scripts`
7. В папке `Contents/bin/jetbra/scripts` применить скрипт `install.sh`
8. Вернуться на зеркало `jetbra`, скопировать ключ активации
9. Запустить `WebStorm`
10. Перейти `Help` -> `Register` -> `Activation Code`
11. Вставить скопированный ранее ключ
12. **PROFIT**

_PS. Желательно отключить обновления `Appearance` -> `System Settings` -> `Updates` -> выключить все чекбоксы_