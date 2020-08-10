requires 'HTML::Selector::XPath', '0.17';
requires 'Scalar::Util', '1.19';
requires 'XML::LibXML', '1.69';
requires 'perl', '5.008';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.59';
    requires 'Test::Base';
    requires 'Test::More', '0.94';
    requires 'Test::Requires';
};
