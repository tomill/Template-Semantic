use t::TestBase;
run_template_process;

__DATA__
=== chomp 1
--- vars
'.data' => [ "foo\n", 'chomp' ]
--- template
<span class="data">xxx</span>
--- expected
<span class="data">foo</span>

=== chomp 2
--- vars
'.data' => [ "foo\n\n", 'chomp' ]
--- template
<span class="data">xxx</span>
--- expected
<span class="data">foo
</span>

=== trim
--- vars
'.data' => [ " foo bar ", 'trim' ]
--- template
<span class="data">xxx</span>
--- expected
<span class="data">foo bar</span>

=== sort
--- vars
'@class' => \&Template::Semantic::Filter::sort
--- template
<span class="yyy xxx zzz">foo</span>
--- expected
<span class="xxx yyy zzz">foo</span>

=== uniq
--- vars
'span/@class' => [ sub { "$_ red" }, 'uniq' ]
--- template
<root>
    <span class="red blue yellow">foo</span>
    <span class="blue yellow">bar</span>
</root>
--- expected
<root>
    <span class="red blue yellow">foo</span>
    <span class="blue yellow red">bar</span>
</root>

=== comma
--- vars
'price' => \&Template::Semantic::Filter::comma
--- template
<root>
    <price>10000</price>
    <price>1000.00</price>
    <price>123.45</price>
    <price>1234.5678</price>
    <price>1234567.8901</price>
    <price>.31</price>
    <price>.3141592</price>
    <price>0.3141592</price>
    <price>3.141592</price>
    <price>314.1592</price>
    <price>31415.92653</price>
    <price>3141592653.58</price>
    <price>314159265358</price>
    <price>This item costs 1000 yen.</price>
    <price>This item costs $123.4567 USD.</price>
</root>
--- expected
<root>
    <price>10,000</price>
    <price>1,000.00</price>
    <price>123.45</price>
    <price>1,234.5678</price>
    <price>1,234,567.8901</price>
    <price>.31</price>
    <price>.3141592</price>
    <price>0.3141592</price>
    <price>3.141592</price>
    <price>314.1592</price>
    <price>31,415.92653</price>
    <price>3,141,592,653.58</price>
    <price>314,159,265,358</price>
    <price>This item costs 1,000 yen.</price>
    <price>This item costs $123.4567 USD.</price>
</root>

=== html_line_break
--- vars
'p' => [
    qq{AAA&A\nBBB<br />BBB\n\nCCC\n},
    'html_line_break',
]
--- template
<root>
    <p></p>
</root>
--- expected
<root>
    <p>AAA&amp;A<br />
BBB&lt;br /&gt;BBB<br />
<br />
CCC<br />
</p>
</root>

=== class->call_filter
--- vars
'@class' => Template::Semantic->call_filter('sort')
--- template
<span class="yyy xxx zzz">foo</span>
--- expected
<span class="xxx yyy zzz">foo</span>
