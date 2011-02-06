require 'test/unit'
require 'kpeg'
require 'kpeg/grammar_renderer'
require 'stringio'

class TestKPegGrammarRenderer < Test::Unit::TestCase
  def test_escape
    str = "hello\nbob"
    assert_equal 'hello\nbob', KPeg::GrammarRenderer.escape(str)
    str = "hello\tbob"
    assert_equal 'hello\tbob', KPeg::GrammarRenderer.escape(str)
    str = "\\"
    assert_equal '\\\\', KPeg::GrammarRenderer.escape(str)
    str = 'hello"bob"'
    assert_equal 'hello\\"bob\\"', KPeg::GrammarRenderer.escape(str)
  end

  def test_dot_render
    gram = KPeg.grammar do |g|
      g.root = g.dot
    end

    io = StringIO.new
    gr = KPeg::GrammarRenderer.new(gram)
    gr.render(io)

    assert_equal "root = .\n", io.string
  end

  def test_tag_render
    gram = KPeg.grammar do |g|
      g.root = g.seq("+", g.t("hello", "greeting"))
    end

    io = StringIO.new
    gr = KPeg::GrammarRenderer.new(gram)
    gr.render(io)

    assert_equal "root = \"+\" \"hello\":greeting\n", io.string
  end

  def test_tag_render_parens
    gram = KPeg.grammar do |g|
      g.root = g.t(g.seq(:b, :c), "greeting")
    end

    io = StringIO.new
    gr = KPeg::GrammarRenderer.new(gram)
    gr.render(io)

    assert_equal "root = (b c):greeting\n", io.string
  end

  def test_grammar_renderer
    gram = KPeg.grammar do |g|
      g.some = g.range('0', '9')
      g.num = g.reg(/[0-9]/)
      g.term = g.any(
                 [:term, "+", :term],
                 [:term, "-", :term],
                 :fact)
      g.fact = g.any(
                 [:fact, "*", :fact],
                 [:fact, "/", :fact],
                 :num
               )
      g.root = g.term
    end

    m = KPeg.match "4*3-8/9", gram

    io = StringIO.new
    gr = KPeg::GrammarRenderer.new(gram)
    gr.render(io)

    expected = <<-GRAM
some = [0-9]
 num = /[0-9]/
term = term "+" term
     | term "-" term
     | fact
fact = fact "*" fact
     | fact "/" fact
     | num
root = term
    GRAM

    assert_equal expected, io.string
  end

  def test_grammar_renderer2
    gram = KPeg.grammar do |g|
      g.num = g.reg(/[0-9]/)
      g.term = g.any(
                 [:term, g.t("+"), :term],
                 [:term, g.any("-", "$"), :term],
                 :fact)
      g.fact = g.any(
                 [:fact, g.t("*", "op"), :fact],
                 [:fact, "/", :fact],
                 :num
               )
      g.root = g.term
    end

    m = KPeg.match "4*3-8/9", gram

    io = StringIO.new
    gr = KPeg::GrammarRenderer.new(gram)
    gr.render(io)

    expected = <<-GRAM
 num = /[0-9]/
term = term "+" term
     | term ("-" | "$") term
     | fact
fact = fact "*":op fact
     | fact "/" fact
     | num
root = term
    GRAM

    assert_equal expected, io.string
  end

end