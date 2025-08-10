# RaycastCameraApp (iOS, SwiftUI + ARKit/RealityKit)

Минимальное приложение на SwiftUI для трассировки луча от камеры:
- В реальном времени отрисовывает луч из центра экрана.
- Луч зелёный при пересечении с обнаруженной плоскостью, иначе красный.
- По тапу ставит сферу в точку пересечения (по месту касания).

## Требования
- Xcode 15+
- iOS 16+ (физическое устройство с поддержкой ARKit — чип A12 или новее)

## Как собрать в Xcode
1. Откройте Xcode ➜ File ➜ New ➜ Project...
2. iOS ➜ App. Название: `RaycastCameraApp`, Interface: SwiftUI, Language: Swift.
3. После создания проекта:
   - Удалите сгенерированный `ContentView.swift` и `AppNameApp.swift` если хотите, или замените их файлами из папки `RaycastCameraApp` этого репозитория:
     - `RaycastCameraApp/RaycastCameraApp.swift`
     - `RaycastCameraApp/ContentView.swift`
   - Добавьте эти файлы в проект (Drag & Drop в корень таргета, отметьте “Copy items if needed”).
4. Настройте доступ к камере и ARKit:
   - В Target ➜ Info добавьте ключ `Privacy - Camera Usage Description` со значением: «Для AR-трассировки нужен доступ к камере.»
   - В Target ➜ Info ➜ Custom iOS Target Properties добавьте `Required device capabilities` ➜ Item 0 = `arkit`.
   - Либо добавьте прилагаемый `RaycastCameraApp/Info.plist` и укажите его как Info.plist у таргета.
5. Подключите физическое устройство и выберите его как Run Destination.
6. Product ➜ Run.

## Управление
- Луч обновляется каждый кадр, исходя из позы камеры.
- Цвет луча: зелёный — есть попадание в плоскость, красный — нет.
- Тап по экрану: попытка трассировки из точки касания и установка сферы в точку попадания.

## Советы
- Медленно поводите устройством, чтобы ARKit смог обнаружить горизонтальные и вертикальные плоскости.
- Хорошее освещение и текстуры в сцене ускоряют инициализацию.

## Структура
- `RaycastCameraApp.swift` — точка входа SwiftUI.
- `ContentView.swift` — обёртка `ARView` и логика трассировки/визуализации.
- `Info.plist` — ключи приватности и требование `arkit`.
