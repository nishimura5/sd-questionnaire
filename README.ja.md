# sd-questionnaire サンプル

GodotでSD法質問紙のデモを実行するためのサンプルプロジェクトです。

## 動作環境

- [Godot 4.6](https://godotengine.org/download/archive/4.6-stable/)で動作確認済みです。

## サンプルの実行

1. Godot Editorでこのプロジェクトを開きます。
2. `Run Project`または`F5`で実行すると、`sample/character_or_car_sample.tscn`が起動します。
3. 回答者IDを入力すると、3DモデルとSD法質問紙が表示されます。
4. すべての刺激に回答すると、回答結果がCSVに出力されます。

![キャプチャ画面](docs/sd_questionnaire_cap.webp)

## character_or_car_sample.tscn

`sample/character_or_car_sample.tscn`は、キャラクターまたは車の3Dモデルを刺激として表示しながらSD法質問紙に回答するためのサンプルシーンです。初期設定では`assets/questionnaire_car.json`を読み込み、`assets/kenney_car`内の車モデルを順番に表示します。

![character_or_car_sample.tscnのノード構成](docs/character_or_car_sample_cap.webp)

### 実行時の流れ

1. ルートノードの`CharacterCarSample`が質問紙JSONを読み込みます。
2. `RespondentIdScreenDialog`で回答者IDを入力します。
3. `ModelRoot`の下に現在の刺激モデルが読み込まれ、`QuestionnaireScreenDialog`にSD法質問紙が表示されます。
4. すべての刺激への回答が終わると、回答結果がCSVに出力されます。

### 各ノード

- `CharacterCarSample`: シーン全体を制御するルートノードです。`sample/character_or_car_sample.gd`がアタッチされており、質問紙JSONの読み込み、刺激モデルの切り替え、回答の収集、CSV出力を行います。Inspectorの`Questionnaire Json Path`を`res://assets/questionnaire_character.json`に変更するとキャラクター用の質問紙に切り替えられます。
- `MainCamera`: 刺激モデルを映す3Dカメラです。読み込む質問紙JSONに応じてカメラの高さが調整され、キャラクターと車のどちらも見やすい位置から表示します。
- `SunLight`: シーン全体に方向性のある光を当てる`DirectionalLight3D`です。影の基準となる主な環境光として使われます。
- `CinematicKeyLight`: 刺激モデルの正面側を照らす`SpotLight3D`です。モデルの形や質感を見やすくするためのメインライトです。
- `CinematicRimLight`: モデルの背面側から輪郭を強調する`SpotLight3D`です。背景や床からモデルを分離して見せます。
- `LowCoolAccent`: 補助的な`OmniLight3D`です。モデル周辺にアクセントライトを足して、暗部がつぶれすぎないようにします。
- `WorldEnvironment`: 空、環境光、トーンマッピング、フォグ、SSAO、SDFGIなどの描画設定をまとめたノードです。シーン全体の明るさや雰囲気を決めます。
- `Floor`: 刺激モデルの下に置かれた床用の`MeshInstance3D`です。モデルの接地感を出し、影を受ける面として使われます。
- `ModelRoot`: 実行時に読み込まれたGLBモデルを追加する親ノードです。次の刺激へ進むたびに現在のモデルを削除し、新しいモデルをこの下に配置します。
- `QuestionnaireScreenDialog`: SD法質問紙を画面上に表示する`CanvasLayer`です。`sd_questionnaire/questionnaire_screen_dialog.gd`がアタッチされており、回答送信時にシーンへ結果を渡します。
- `QuestionnairePanel`: 質問文、尺度、送信ボタン、`x/y`形式の回答状況を持つ質問紙UIです。`sd_questionnaire/questionnaire_panel.tscn`のインスタンスで、刺激が表示されるまで非表示になっています。
- `RespondentIdScreenDialog`: 回答者ID入力UIを画面上に表示する`CanvasLayer`です。回答開始前に表示され、入力されたIDをCSV出力時に使用します。
- `RespondentIdPanel`: 回答者ID入力欄と送信ボタンを持つUIです。`sd_questionnaire/respondent_id_panel.tscn`のインスタンスで、`RespondentIdScreenDialog`から表示されます。

## sample.tscn

`sample/sample.tscn`をCurrent Sceneにして`Run Current Scene`または`F6`で実行すると、`assets/questionnaire.json`に基づいてSD法質問紙を起動できます。

`sample/sample.tscn`では、`assets`フォルダ直下に配置したGLBファイルを刺激として表示できます。GLBファイルを追加したあと、必要に応じて`assets/questionnaire.json`を編集してください。

`sample/desktop_sample.tscn`では、`assets/questionnaire_desktop.json`の`root_dir`に指定した外部ディレクトリからGLBファイルを読み込みます。初期設定は`~/Desktop`です。

`sample/thumbnail_generator.tscn`を実行すると、`assets/questionnaire_desktop.json`に基づき、`desktop_sample.tscn`と同じ刺激の600x600 PNGサムネイルを一括生成します。`use_subdirectory`によるフォルダ選択が必要な場合は、起動後に対象フォルダを選択してください。画像は`csv_output_directory`で指定したディレクトリ内の`thumb`フォルダへ保存されます。ファイル名は刺激IDから末尾の`.glb`を除いた`<stimulus_id>.png`形式です（例: `001.glb`は`001.png`）。輪郭のジャギーを抑えるため、サムネイル用Viewportでは4x MSAAを使用します。処理完了後にシーンは自動終了します。カメラと光源は`thumbnail_generator.tscn`の`ThumbnailViewport`内で調整できます。

## questionnaire.jsonのルール

`assets/questionnaire.json`は、表示する刺激、尺度の点数、形容詞対、ランダム化、CSV出力先を定義します。

```json
{
  "root_dir": "~/Desktop",
  "stimuli": [
    {
      "id": "s_001",
      "description": "sample model",
      "file_name": "sample.glb"
    }
  ],
  "load_all_glbs": true,
  "use_subdirectory": true,
  "points": 7,
  "adjective_pairs": [
    ["明るい", "暗い"],
    {
      "id": "warm-cold",
      "left": "暖かい",
      "right": "冷たい"
    }
  ],
  "randomise": {
    "stimuli": true,
    "adjective_pairs": true
  },
  "csv_file_name": "questionnaire_results.csv",
  "csv_output_directory": "Desktop"
}
```

### 各項目

- `stimuli`: 刺激として表示するGLBファイルの一覧です。
- `stimuli[].id`: 刺激のIDです。省略した場合は`file_name`の拡張子なしファイル名が使われます。重複はできません。
- `stimuli[].description`: 質問紙に表示する刺激の説明です。省略できます。
- `stimuli[].file_name`: `root_dir`からの相対パスです。`root_dir`未指定時は`assets`フォルダからの相対パスです。`sample.glb`や`kenney_car/van.glb`のように指定します。
- `root_dir`: GLBファイルを探す起点ディレクトリです。`~/Desktop`のように指定するとDesktop上のGLBを読み込みます。省略時は従来通り`res://assets`です。
- `load_all_glbs`: `true`にすると、`root_dir`または`assets`直下の未指定GLBファイルも刺激に追加します。
- `use_subdirectory`: `true`かつ`load_all_glbs`も`true`で、`root_dir`にサブフォルダがある場合、回答者ID入力画面にフォルダ選択メニューを表示します。選択したサブフォルダ直下のGLBファイルだけが自動追加され、この場合の`stimuli[].file_name`は選択したサブフォルダからの相対パスとして扱われます。
- `points`: SD法尺度の段階数です。`5`または`7`を指定します。
- `adjective_pairs`: 形容詞対の一覧です。`["左ラベル", "右ラベル"]`形式、または`{"id": "...", "left": "...", "right": "..."}`形式で指定できます。
- `adjective_pairs[].id`: CSVの列名として使われます。省略した場合は`left-right`形式のIDが自動生成されます。重複はできません。
- `randomise.stimuli`: `true`にすると刺激の表示順をランダム化します。
- `randomise.adjective_pairs`: `true`にすると形容詞対の表示順をランダム化します。
- `csv_file_name`: 出力するCSVファイル名です。省略時は`sd_answers.csv`です。
- `csv_output_directory`: CSVの出力先です。`Desktop`、`Downloads`、`Documents`、または`~/Desktop`のような形式を指定できます。省略時は`Desktop`です。

CSVには、`id`、`respondent_id`、`answer_start_datetime`（回答開始時刻）、`file_save_datetime`（ファイル保存時刻）、`stimulus_id`、各形容詞対の回答値が出力されます。サブフォルダを選択した場合、`stimulus_id`は`foldername/stimulus_id`形式になります。
