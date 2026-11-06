# <img src="cygterm-logo.gif" align="absmiddle" width="150"> ターミナル・エミュレータによる Cygwin コンソール
v1.08a - 2017/03/31 &nbsp; Copyright(C) 2000-2017 NSym.

= [English](README.md) / Japanese =

## CygTermの概要

Cygwinでは、DOS窓上で bash などのシェルが使えるようになっていますね。しかしDOS窓ではサイズの制限やコピー&ペーストなど、いろいろ使いにくいです。普段UnixマシンをTelnetで使っている人は多いと思います。Cygwinもそれと同じように使いたい、つまり VT100 のターミナル・エミュレータで操作したいものです。

まず考えられる方法は、Cygwin で inetd in.telnetd 等を準備し、ターミナル・エミュレータからログイン、という方法でしょうか...　でもここでは、もうひとつの方法について紹介します。

簡単に説明すると、ターミナル・エミュレータと Cygwin シェルを直接つなぐ、というものです。ログインの必要がなく、単に cygwin.bat の DOS窓 に代わって VT100エミュレータ になる、という感じです。

## 考え方

ターミナル・エミュレータと Cygwin のシェルを起動し、両者を中継するプログラムを作ればよい。このプログラムを起動すると、指定のターミナル・エミュレータが立ち上がり、その中で Cygwin のプロンプトが現れる、というものです。  
[スクリーンショット](cygterm-shot.gif)

## 設計

### cygterm.exe の処理詳細

| ステップ | 処理内容 |
| :--- | :--- |
| **[1]** | TELNET接続を待ち受けるリスナーソケットを用意する。ソケットに割り当てる未使用ポート番号は指定範囲内から探し出す。 |
| **[2]** | 別スレッドでターミナル・エミュレータを起動する。このとき起動引数に IPアドレス `127.0.0.1` と [1]のポート番号を指定する。 |
| **[3]** | ターミナル・エミュレータからの接続を受け入れる。セキュリティー上 `127.0.0.1` 以外からの接続は却下する。 |
| **[4]** | `fork()` した子プロセス上、PTY(擬似端末)スレーブ側でシェルを起動する。 |
| **[5]** | [3]の TELNET接続ソケットと [4]の PTYマスター側の入出力を橋渡しする。 |

### TELNETプロトコルへの対応 (option negotiation)

* ターミナル・エミュレータからターミナルタイプの通知を受け、シェル上 `TERM` 環境変数にセットする。
* ターミナル・エミュレータからターミナルサイズの通知を受け、PTYのウィンドウサイズを同サイズに変更する。
* [参照: RFC854 TELNET PROTOCOL SPECIFICATION]
* `cygterm.exe` はウィンドウを持たない Win32アプリとして作成する。

## ダウンロード

ソース一式です。

| ファイル | 内容 |
| :--- | :--- |
| `Makefile` | メイクファイル |
| `cygterm.cc` | ソースコード |
| `cygterm.cfg` | 設定ファイル |
| `cygterm_here.reg` | 右クリックメニュー用レジストリファイルのサンプル |

[ダウンロード cygterm108a.tgz (約8KB)](https://github.com/nsoft-lab/CygTerm/releases/download/v1.08a/cygterm108a.tgz)


> **--- ライセンス ---**  
> Free Software Foundation 発行  
> **GNU General Public License (GPL)** に準拠するフリーソフトウェアとして配布します。[GPL (http://www.gnu.org/copyleft/gpl.html)](http://www.gnu.org/copyleft/gpl.html) 参照。  
>  
> **--- 補足 ---**  
> 他プログラムが CygTerm実行形式 (`cygterm.exe`) を起動し通信して使用することは、それが 非GPLプログラムの場合でも 許可されます。

## インストール

Cygwin環境下で `make install` を実行します。

> インストール先ディレクトリは Makefile 中 `BINDIR` で設定しておきます。`BINDIR` に `cygterm.exe` と `cygterm.cfg` がインストールされます。`cygterm.cfg` は上書きされません。

> `make with-icon; make install` で Cygwinアイコン付きにできます。

## 設定ファイル

`cygterm.cfg` は設定ファイルです。使用するターミナル・エミュレータのコマンドラインや起動するシェルのコマンドライン等を設定します。`cygterm.cfg` は `cygterm.exe` と同じディレクトリにないといけません。

```ini
cygterm.cfg の例      
+-----------------------------------------------------------------------      
| TERM = C:\program files\ttermpro\ttermpro.exe %s %d /KR=SJIS /KT=SJIS      
| TERM_TYPE = vt100      
| PORT_START = 20000      
| PORT_RANGE = 40      
| SHELL = /bin/bash      
| ENV_1 = MAKE_MODE=unix      
| ENV_2 = HOME=/home      
|   :         :
```

- **`TERM`**: ターミナル・エミュレータの起動コマンドラインです。コマンド名は Windows環境でパスが通ってなければフルパスで書きます。ホスト指定のところは `%s` とし、ポート指定のところは `%d` とします。
- **`TERM_TYPE`**: ターミナル・エミュレータがターミナルタイプを与えてくれなかった場合に採用するターミナルタイプです。 (デフォルト: `vt100`) シェル上、環境変数 `TERM` にセットされます。
- **`PORT_START`**: 使い始める (使ってよい最小の) ポート番号です。 (デフォルト: `20000`)
- **`PORT_RANGE`**: 使ってよいポート番号の個数です。 (デフォルト: `40`) `PORT_START` 〜 `PORT_START+PORT_RANGE` の範囲で空きポートを探します。この数だけ同時実行できることになります。
- **`SHELL`**: Cygwin側シェル (通常 `/bin/bash`) の起動コマンドラインです。コマンド名はフルパスでなければいけません。
- **`ENV_X`**: シェル起動時に設定しておきたい環境変数です。「`変数名=値`」の形式 (`putenv`形式) で記述します。 `ENV_` で始めればいくつでも記述できます。

## 起動方法

### コマンドライン・オプション

```console
cygterm.exe [-t 'terminal-emulator'] [-p port-number] [-dumb]
            [-s 'shell'] [-v 'env-var' ...]
```

- **`-t 'terminal-emulator'`**  
  ターミナル・エミュレータを指定します。指定形式は設定ファイルの `TERM` と同じです。空白文字を含む場合は必ずクォートで囲みます。
- **`-p port-number`**  
  ターミナル・エミュレータを起動するのではなく、ローカルホストのこのポート番号への接続を試みます。他のアプリケーション・プログラムが `-p` オプションを使って `cygterm.exe` 経由で Cygwinを利用する、等が考えられます。
- **`-dumb`**  
  TELNETオプション・ネゴシエーションを行いません。さらに TELNETコマンドが送信されてきても無視します。シェル側の環境変数 `TERM` は `'dumb'` となります。
- **`-s 'shell'`**  
  Cygwin上のシェルを指定します。指定形式は設定ファイルの `SHELL` と同じです。空白文字を含む場合は必ずクォートで囲みます。必ずしもシェルコマンドである必要はありません。
- **`-v 'env-var'`**  
  シェル起動時に設定しておきたい環境変数を指定します。指定形式は設定ファイルの `ENV_X` と同じです。空白文字を含む場合は必ずクォートで囲みます。`-v` オプションはいくつでも指定できます。

---

- ターミナル・エミュレータもしくは接続先ポート番号、と Cygwin側シェルの指定が最低必要となります。これらがコマンドライン・オプションによって与えられるならば、設定ファイル `cygterm.cfg` が無くても実行できます。
- `cygterm.exe` は `cygwin1.dll` を利用する Win32アプリケーションです。Cygwin上から実行することも、Windows上のショートカットから実行することもできます。

> Windows上から実行するには `cygwin1.dll` のディレクトリパスが Windows環境変数 `PATH` に追加されている必要があります。(通常 `Cygwinルートディレクトリ\bin`)

## 注意

> **TeraTerm使用時の注意**  
> ターミナル・エミュレータが TeraTerm の場合、`cygterm.exe` から起動された状態で設定保存 `[Setup][Save setup]` を行わないよう注意してください。 TCP/IP設定の Telnetポート番号が 23 以外で保存され、通常の Telnet目的の実行時に接続できず、慌てることになってしまいます。 TCP/IP Port# に 23 を指定して設定保存し直せば元に戻ります。

## 動作確認

2017年 4月現在、以下の環境で動作が確認できています。

- Cygwin 64bit 2.7 (`/bin/bash`)
- Windows 10 64bit
- TeraTerm 4.87

<address>バグ報告・ご意見等はこちらへ &lt;nsym@dd.iij4u.or.jp&gt;</address>

## 変更履歴

- **v1.08a (2017/03/31)**
  - Makefile: gccコンパイラオプション (`-D_GNU_SOURCE`) 追加。
  - エクスプローラ右クリック用レジストリ設定例 (`cygterm_here.reg`) 追加。

- **v1.08 (2015/08/16)**
  - ターミナルエミュレータで line-at-a-time 動作にならないよう、TELNETネゴシエーションに `WILL ECHO` を加えた。
  - `TERM` 環境変数が正しくセットされるよう修正。
  - read-only の `char*` 変数に `const` を付けた。(gcc Warning回避)
  - 設定サンプル `cygterm.cfg` 記述内容の変更
    - teratermコマンドラインにオプション `/T=1` 追加。
    - teratermのパスを `C:\Program Files (x86)\...` に変更。

- **v1.07 (2006/11/26)**
  - gcc 3.4 での `WinMainCRTStartup()` 再定義エラー回避
  - 連続出力時でもキーボード割り込みが入るように。

- **v1.06 (2004/01/24)**
  - コマンドライン・オプションを追加。
    - `-t 'terminal-emulator'` (ターミナル・エミュレータ指定)
    - `-p port-number` (接続先ポート番号指定)
    - `-dumb` (ダムターミナル指定)
    - `-s 'shell'` (シェル指定)
    - `-v 'env-var'` (環境変数指定)
  - Makefile修正: `make install` で `BINDIR` が存在しなければエラーになるように。
  - ソースファイル英文化 (`cygterm.cc`, `README.txt`)

- **v1.05 (2003/01/14)**
  - Ctrl+SPACE(NUL)が送信できるように修正。改行コード CR+NUL を処理する方法として単純に NUL文字を無視していたため、Ctrl+SPACE 押下時でも NUL が送信されなかった。

- **v1.04 (2002/12/08)**
  - ターミナル・エミュレータおよびシェルの起動に失敗したときにエラーメッセージを表示するようにした。
  - Makefile修正: `make install` で `cygterm.cfg` を上書きしないように。gccオプションに `-fno-exceptions` を追加、GCC-3のリンクエラー回避。

- **v1.03 (2002/07/24)**
  - ターミナル・エミュレータが通知してくるターミナルタイプに、大文字が含まれていれば、それを小文字に変換するように修正。ターミナル・エミュレータによっては環境変数 TERM の値が 'ANSI' 'VT100' のように大文字になり terminfo にマッチしないため。(Windows 2000 `telnet.exe` 等)

- **v1.02 (2002/07/22)**
  - ターミナル・エミュレータがコンソール・アプリケーションのときに起動できなかったのを修正。(Windows 2000 `telnet.exe` 等、`CreateProcess()` 呼出しミス)
  - ターミナル・エミュレータから CR+LF が送られてきたら LF は転送しないようにし、改行が２回発生するのを修正。(Windows 98 `telnet.exe` 等)
  - バージョン番号を `cygterm.exe` に埋め込むようにした。(確認方法は `$ strings cygterm.exe | grep version`)

- **v1.01 (2002/07/19)**
  - zsh, tcsh で動作しなかったのを修正。擬似端末のオープン方法が悪く、zsh, tcsh では起動とともに入力がブロックされた。

- **v1.00 (2000/12/17)**
  - 初期バージョン完成
