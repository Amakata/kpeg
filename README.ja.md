# kpeg

home :: https://github.com/evanphx/kpeg
bugs :: https://github.com/evanphx/kpeg/issues

## 概要

KPegはRubyのシンプルなPEGライブラリです。文法を構築するためのネイティブ文法のようなAPIを提供します。
KPegは、単純で強力なAPIとなることを心がけています。

KPegは、[OMeta メモ化](http://www.vpri.org/pdf/tr2008003_experimenting.pdf)トリックを利用して直接、ルールの左再起に対応します。

## 最初の文法

### 文法の設定

すべての文法は、パーサーのclass/module名から始まります。

```
%% name = Example::Parser
```

その後に、パーサのclassの本体に追加したいRubyコードのブロックを定義できます。

このブロックで定義されている属性は、インスタンス変数としてのパーサ内でアクセスすることができます。
このブロックで定義されているメソッドは、アクションブロックのように利用できます。

```
%% {
  attr_accessor :something_cool

  def something_awesome
    # なにか処理する
  end
}
```

### リテラルの定義

リテラルは、静的な文字列の宣言か、文法で再利用するために設定された正規表現です。これらは、定数または変数にできます。リテラルは、文字列、正規表現または文字の範囲を指定できます。
```
ALPHA = /[A-Za-z]/
DIGIT = /[0-9]/
period = "."
string = "a string"
regex = /(regexs?)+/
char_range = [b-t]
```

リテラルは、複数の定義も指定できます。

```
vowel = "a" | "e" | "i" | "o" | "u"
alpha = /[A-Z]/ | /[a-z]/
```

### 変数のルールの定義

文字列のパースを開始できるようになるより前に、文字列のacceptまたはrejectを用いたルールを定義する必要があります。
kpegでは利用可能な多くの異なるタイプのルールがあります。

もっとも基本的なそれらのルールは、文字列の読み取り(capture)です。

```
alpha = < /[A-Za-z]/ > { text }
```

以前に定義されたalphaリテラルにとてもよくにて見えるが、それとは異なり一つの重要な方法で、<と>記号の間に定義されたルールによって読み込まれたテキストは、次のブロック内のテキスト変数として設定されます。
また、明示的に、既存のルールやリテラルにのみ、希望する変数も定義することができます。

```
letter = alpha:a { a }
```

加えて、ブロックは、ブロックの式に基づいてtrueまたfalseの値を返すことができる。以下のようにすると、テストがパスしたら、trueを返す：

```
match_greater_than_10 = < num:n > &{ n > 10 }
```

テストがパスするような状況でテストをしてfalse値を返すには、以下のようにする：

```
do_not_match_greater_than_10 = < num:n > !{ n > 10 }
```

ルールは、関数やパラメータを取るようなactもできます。この例は、[Email List
Validator](https://github.com/larb/email_address_validator)から咲くようしてきたもので、
アスキー値が渡されると、文字が評価され、それが一致した場合には、真を返します。

```
d(num) = <.> &{ text[0] == num }
```

ルールは、いつくかのマッチングのための正規表現シンタックスに対応します。

* maybe ?
* many +
* kleene *
* groupings ()

例)

```
letters = alpha+
words = alpha+ space* period?
sentence = (letters+ | space+)+
```

Kpegは、範囲の形式で、マッチの受け売れられる数を定義するルールも許します。

正規表現で、これはしばしば```{0,3}```のようなシンタックスで示されます。
Kpegは、一致する範囲を指定するために、このシンタックス```[最小値, 最大値]```を使います。

```
matches_3_to_5_times = letter[3,5]
matches_3_to_any_times = letter[3,*]
```

### アクションの定義

Illustrated above in some of the examples, kpeg allows you to perform actions
based upon a match that are described in block provided or in the rule
definition itself.


前に示された例のいくつかでは、kpegは、マッチした場合に、提供されたブロック内、またはルール宣言それ自体で記載されているアクションを実行することができます。

```
num = /[1-9][0-9]*/
sum = < num:n1 "+" num:n2 > { n1 + n2 }
```

バージョン0.8には別の構文が、アクションとして定義されたメソッドを呼び出すために追加されました。

```
%% {
  def add(n1, n2){
    n1 + n2
  }
}
num = /[1-9][0-9]*/
sum = < num:n1 "+" num:n2 > ~add(n1, n2)
```

### 外部文法の参照

kpegは、外部文法で定義されたルールを実行することができます。
別のパーサで再利用したいルールの定義されたセットがある場合に便利です。
これを行うには、文法を作成し、 kpegコマンドラインツールを使用してパーサーを生成します。

```
kpeg literals.kpeg
```

生成されたパーサを取得したら、新しい文法にそのファイルを含めます。

```
%{
  require "literals.kpeg.rb"
}
```


そして、外部インターフェイスに保持し、それをパーサのクラス名を渡すために、変数を作成します。
この場合、パーサクラス名はLiteralです


```
%foreign_grammar = Literal
```

以下のように、ローカルの文法ファイルで外部文法で定義されたルールを使用することができます。

```
sentence = (%foreign_grammar.alpha %foreign_grammar.space*)+
           %foreign_grammar.period
```

### コメント

Kpegは、#シンボルを使って、文法ファイルにコメントを追加することができます。

```
# This is a comment in my grammar
```

### 変数

変数は下記のようになります：

```
%% name = value
```
Kpeg allows the following variables that control the output parser:

Kpegは、パーサの出力を制御するための以下の変数を許すます。

* name
  生成されたパーサのクラス名
* custom_initialize
 スタンドアロンのパーサとして構築する場合、デフォルトでは初期化のメソッドは含まれません。

### ディレクティブ

ディレクティブは下記のようになります：

```
%% header {
  ...
}
```

Kpegは、以下のディレクティブを許します：

* header
  生成されたコードより前に配置される
* pre-class
  クラスのコメントを提供するために、クラス定義の前に置かれる。
* footer
  クラスの終了後に置かれる。(パーサの名前空間に依存した要求されるファイルのため)

## パーサーの生成と実行

パーサを生成するためにはその前に、ルートルールを定義する必要があります。
これは、パーサーに指定した文字列に対する最初のルールです。

```
root = sentence
```

パーサを生成するには、引数としてkpegファイル（複数可）でkpegコマンドを実行します。
これはあなたの文法ファイルと同じ名前を持つRubyのファイルを生成します。

```
kpeg example.kpeg
```

Include your generated parser file into an application that you want to use　the parser in and run it.
Create a new instance of the parser and pass in the　string you want to evaluate.
When parse is called on the parser instance it　will return a true if the sting is matched, or false if it doesn't.


パーサーを使用しそれを実行するアプリケーションへ、生成されたパーサーファイルをインクルードします。

パーサの新しいインスタンスを作成し、評価したい文字列を渡します。
解析はパーサインスタンスで呼び出されると、それがない場合には刺し傷が一致する場合はtrueを返し、またはfalseになります。

```
require "example.kpeg.rb"

parser = Example::Parser.new(string_to_evaluate)
parser.parse
```

## ショートカットとその他のテクニック

vitoごとに、次のように現在の行または現在の列を取得することができます。

```
line = { current_line }
column = { current_column }
foo = line:line ... { # use line here }
```

## AST 生成

Kpeg 0.8のから、パーサーはASTを生成することができます。ASTノードを定義するためには、次の構文を使用します。

```
%% assign = ast Assignment(name, value)
```

定義されたASTノードを取得したら、それは文法で使用することができます。

```
assignment = identifier:i space* = space* value:v ~assign(i,v)
```

これは、新しい割り当てノードを作成し、ASTに追加することができます。

よりより例は、[Talon](https://github.com/evanphx/talon)をチェックアウトしてください。

## 例

/examplesディレクトリには、利用可能ないくつかの例があります。
上記のパーサは、文法のステップバイステップの説明とreadmeファイルがあります。

## kpegを用いたプロジェクト

[Dang](https://github.com/veganstraightedge/dang)

[Email Address Validator](https://github.com/larb/email_address_validatorO)

[Callisto](https://github.com/dwaite/Callisto)

[Doodle](https://github.com/vito/doodle)

[Kanbanpad](https://kanbanpad.com) (何かを入力してくださいのバーの解析のためのkpegを使用しています)


## 翻訳者による補足

### 肯定先読み

Kpegでは、肯定先読みをサポートしている。&のシンボルをルールの前に記載すると、肯定先読みになる。

```
BulletList = &Bullet ListTight:c
```
という文法があった場合、まず最初にBulletがマッチするか試され、もしマッチしたら、一度読込位置をBulletを読む前の状態にもどし、ListTightのマッチにすすむ。
Bulletにマッチしなかったら、やはり読込位置をBulletの前のに戻しこの文法にはマッチしない。


### 否定先読み

Kpegでは、否定先読みをサポートしている。!のシンボルをルールの前に記載すると、否定先読みになる。

```
ListBlock = !BlankLine Line:c ListBlockLine*:cc
```
という文法があった場合、まず最初にBlankLineがマッチしないことが試され、もしマッチしなかったら、一度読込位置をBlankLineを読む前の状態にもどし、Lineのマッチにすすむ。
BlankLineにマッチしたら、やはり読込位置をBlankLineの前に戻しこの文法にはマッチしない。
