# Shoulder Watch

[![Build](https://github.com/ksd6700/shoulder-watch-mac/actions/workflows/build.yml/badge.svg)](https://github.com/ksd6700/shoulder-watch-mac/actions/workflows/build.yml)

喫茶店などで横から画面を見ている人がいないか、Mac のカメラでざっくり監視する小さなメニューバー常駐アプリです。

## できること

- カメラ映像をこの Mac 内だけで解析します
- Apple Vision で顔の数を検出します
- カメラプレビューは表示しません
- 顔が指定人数以上、短時間続けて映ると画面端に赤い警告を表示します
- 必要ならアプリ内生成の短い警告音を鳴らします
- メニューバーの目アイコンから監視開始/停止、警告音、人数しきい値を変更できます
- メニューバーまたは設定画面からテスト音を鳴らせます

## ビルド

```bash
./build.sh
```

## アイコン再生成

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift \
  -module-cache-path build/ModuleCache \
  Tools/MakeIcon.swift Resources/AppIcon.png Resources/ShoulderWatch.iconset Resources/ShoulderWatch.icns
./build.sh
```

## 起動

```bash
open build/ShoulderWatch.app
```

初回起動時にカメラ権限を求められます。拒否した場合は、システム設定の「プライバシーとセキュリティ > カメラ」から許可してください。

起動後は Dock ではなくメニューバーに目のアイコンが表示されます。設定画面を開く場合は、そのアイコンから「設定を開く...」を選んでください。

## テスト配布用 ZIP

```bash
./package.sh
```

生成物:

```text
dist/ShoulderWatch-0.1.0-mac-arm64.zip
```

この ZIP はテスト配布向けです。広く配布する場合は、Apple Developer ID で署名して notarization を通すと、Gatekeeper の警告をかなり減らせます。

## LPサイト

ブラウザで次を開くと、静的なランディングページを確認できます。

```text
site/index.html
```

## 注意

これは軽量な覗き見アラートです。顔の向き、視線、個人識別は行いません。映像の保存やネットワーク送信もしません。

## License

MIT
