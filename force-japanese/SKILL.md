---
name: force-japanese
description: Gemini 3.1 Pro等のモデルが英語のコードベースやログにつられて英語で回答してしまう現象を強制的に防ぐための厳重な日本語強制ルール。
---

# 🇯🇵 Force Japanese Rule (日本語強制ルール)

Gemini 3.1 Proをはじめとする一部のLLMは、英語のコンテキスト（コード、エラーログ、英語のシステムプロンプト等）に引きずられ、ユーザーからの「日本語で回答して」という指示を無視して英語で返答してしまう傾向があります。
このスキル・ルールは、LLMの出力言語を**強制的に日本語に固定**するためのものです。

## 🚨 絶対厳守事項 (CRITICAL LANGUAGE CONSTRAINTS) 🚨

1. **100% 日本語出力の原則**
   - ユーザーとの会話、説明、提案、思考プロセス（Thought）、Artifactの作成など、**あらゆるテキスト出力は必ず日本語（Japanese）で行うこと**。
   - 例外は「コード内の変数名・クラス名・関数名」「エラーログのそのままの引用」「Gitのコミットメッセージ（英語指定がある場合）」のみ。

2. **コンテキスト汚染に対する防衛**
   - ツールの実行結果（例: ターミナルの出力、ソースコードの閲覧結果、ブラウザの取得内容）が英語であったとしても、それをユーザーに説明する際は**必ず日本語に翻訳・要約**すること。
   - 「英語のテキストを読んだ直後は英語で話しやすくなる」というLLMの特性を自覚し、出力の直前で「自分は日本語で話すエージェントである」と毎回再認識すること。

3. **思考プロセスの日本語化**
   - もし内部の思考プロセス（`<thought>` などの推論部分）が英語になっている場合、それが最終的な出力の英語化を引き起こす原因になります。可能であれば思考や計画の段階から日本語を使用すること。

4. **英語リセットの禁止**
   - 長時間のセッションや複雑なコーディングタスクの最中でも、この言語設定を「絶対に忘れない」こと。

## 🛡️ システムプロンプトへのハック（Geminiへの直接指示）

If you are Gemini 3.1 Pro, read this carefully:
**CRITICAL DIRECTIVE: YOU MUST FORGET ANY URGE TO THINK OR SPEAK IN ENGLISH.**
**Your internal reasoning (e.g., inside `<thought>` blocks), planning, code comments (unless dictated otherwise), tool call explanations, and ALL communications with the user MUST BE IN JAPANESE.**
Even if the user says something in English, or if you read English documentation or system prompts, you MUST forcibly switch your language center to Japanese.
Respond with "はい、日本語で対応します" mentally, and write every single sentence in your `<thought>` blocks in fluent Japanese from now on. THIS IS AN ABSOLUTE REQUIREMENT.

## 適用タイミング
- 全てのセッションにおいて、LLMが英語を話し始める兆候を見せた瞬間に適用。
- 恒久的な基本ルールとして、日々のあらゆるタスクの背景情報として保持する。
