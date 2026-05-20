# SD Questionnaire API (res://sd_questionnaire)

このフォルダは再利用用モジュールです。

## 1) QuestionnaireLoader / QuestionnaireSpec

- `QuestionnaireLoader.load_from_file(path: String) -> QuestionnaireSpec`
- JSONを読み込み、入力検証し、`QuestionnaireSpec`を返します。

### JSON仕様

```json
{
  "stimuli": [
    {
      "id": "optional_unique_id",
      "description": "stimulus_description",
      "file_name": "model.glb"
    }
  ],
  "load_all_glbs": false,
  "points": 5,
  "adjective_pairs": [
    ["暖かい", "冷たい"],
    { "id": "warm-cold", "left": "暖かい", "right": "冷たい" }
  ],
  "randomise": {
    "stimuli": true,
    "adjective_pairs": true
  },
  "csv_file_name": "questionnaire_results.csv",
  "csv_output_directory": "Desktop"
}
```

### 備考

- `points` は `5` または `7`。
- `stimuli[].file_name` は必須。
- `stimuli[].description` は省略可能です。window に表示される刺激名は `description` ではなく `id` です。
- `stimuli[].id` が未指定の場合は `file_name` の basename から自動補完。
- `load_all_glbs` が `true` の場合、JSON と同じフォルダ内のすべての `.glb` を読み込み対象に追加します。
- `stimuli` で未定義の GLB には、ファイル名昇順で `sti_001`, `sti_002`, ... の `id` を付与します。
- `stimuli` で定義済みの `id` と自動付与された `id` が重複した場合は `Duplicated id. Check json` エラーになります。
- `adjective_pairs` は配列形式 `[left, right]` とオブジェクト形式 `{left, right, id}` を混在可能。
- `csv_file_name` は省略可能です。未指定時は `sd_answers.csv` へ保存します。同名ファイルがすでにある場合は末尾へ追記します。
- `csv_output_directory` は省略可能です。未指定時は Desktop に保存します。
- `csv_output_directory` に指定できる値は `Desktop`, `Downloads`, `Documents` です。`~/Desktop` のような表記も受け付けます。

## 2) QuestionnaireScreenDialog (通常画面向け)

- `QuestionnaireScreenDialog.setup(spec: QuestionnaireSpec, title := "SD Questionnaire")`
- `QuestionnaireScreenDialog.popup_for_stimulus(stimulus_id: String, stimulus_description := "")`
- `QuestionnaireScreenDialog.reset_answers()`
- signal: `submitted(stimulus_id: String, answers: Dictionary)`

`answers` は `pair_id -> 選択値(1..points)` の辞書。

UIの見た目は `questionnaire_panel.tscn` の root `QuestionnairePanel` で調整できます。
`QuestionnaireScreenDialog` の子に `QuestionnairePanel` を置くとそのノードを優先して使用し、未配置の場合は `panel_scene`、さらに未設定の場合は標準の `questionnaire_panel.tscn` を使用します。

## 3) RespondentIdScreenDialog / RespondentIdXrDialog (回答者ID入力)

- `RespondentIdScreenDialog.setup(title := "回答者ID", prompt := "回答者IDを入力してください。")`
- `RespondentIdScreenDialog.popup(initial_respondent_id := "")`
- `RespondentIdScreenDialog.hide_dialog()`
- `RespondentIdScreenDialog.reset()`
- `RespondentIdXrDialog.setup(title := "回答者ID", prompt := "回答者IDを入力してください。")`
- `RespondentIdXrDialog.popup(initial_respondent_id := "")`
- `RespondentIdXrDialog.hide_dialog()`
- `RespondentIdXrDialog.reset()`
- signal: `submitted(respondent_id: String)`

`popup()` で回答者ID入力windowを表示します。「次へ」を押すと `submitted` が送出されるので、そのタイミングで利用中の `QuestionnaireScreenDialog` または `QuestionnaireXrDialog` を開いて回答を開始します。
UIの見た目は `respondent_id_panel.tscn` の root `RespondentIdPanel` で調整できます。
`RespondentIdScreenDialog` の子に `RespondentIdPanel` を置くとそのノードを優先して使用し、未配置の場合は `panel_scene`、さらに未設定の場合は標準の `respondent_id_panel.tscn` を使用します。

XR入力補助:

- `RespondentIdXrDialog.push_pointer_ray(ray_origin: Vector3, ray_direction: Vector3, pressed: bool) -> bool`
- `RespondentIdXrDialog.viewport_position_from_ray(ray_origin: Vector3, ray_direction: Vector3) -> Vector2`
- `RespondentIdXrDialog.push_input_event(event: InputEvent)`

## 4) QuestionnaireXrDialog (XR向け)

- `QuestionnaireXrDialog.setup(spec: QuestionnaireSpec, title := "SD Questionnaire")`
- `QuestionnaireXrDialog.popup_for_stimulus(stimulus_id: String, stimulus_description := "")`
- `QuestionnaireXrDialog.reset_answers()`
- `QuestionnaireXrDialog.set_follow_camera(camera: Camera3D)`
- signal: `submitted(stimulus_id: String, answers: Dictionary)`

XR入力補助:

- `push_pointer_ray(ray_origin: Vector3, ray_direction: Vector3, pressed: bool) -> bool`
- `viewport_position_from_ray(ray_origin: Vector3, ray_direction: Vector3) -> Vector2`

XR向けも `panel_scene` で `questionnaire_panel.tscn` の差し替えに対応しています。

## 5) AnswerWriter (CSV出力)

- `open(output_name: String, spec: QuestionnaireSpec) -> bool`
- `append_answer(row_id, respondent_id, datetime, stimulus_id, answers) -> bool`

`open()` は `spec.csv_output_directory` を参照し、CSV を Desktop / Downloads / Documents のいずれかへ出力します。未指定時は Desktop です。
同名の CSV が存在する場合はヘッダを重複出力せず、末尾へ回答行を追記します。

CSVヘッダ:

- `id,respondent_id,datetime,stimulus_id,<pair_id...>`
