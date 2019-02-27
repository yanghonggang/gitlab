require 'spec_helper'

describe Banzai::Filter::AutolinkFilter do
  include FilterSpecHelper

  let(:link) { 'http://about.gitlab.com/' }
  let(:quotes) { ['"', "'"] }

  it 'does nothing when :autolink is false' do
    exp = act = link
    expect(filter(act, autolink: false).to_html).to eq exp
  end

  it 'does nothing with non-link text' do
    exp = act = 'This text contains no links to autolink'
    expect(filter(act).to_html).to eq exp
  end

  context 'Various schemes' do
    it 'autolinks http' do
      doc = filter("See #{link}")
      expect(doc.at_css('a').text).to eq link
      expect(doc.at_css('a')['href']).to eq link
    end

    it 'autolinks https' do
      link = 'https://google.com/'
      doc = filter("See #{link}")

      expect(doc.at_css('a').text).to eq link
      expect(doc.at_css('a')['href']).to eq link
    end

    it 'autolinks ftp' do
      link = 'ftp://ftp.us.debian.org/debian/'
      doc = filter("See #{link}")

      expect(doc.at_css('a').text).to eq link
      expect(doc.at_css('a')['href']).to eq link
    end

    it 'autolinks short URLs' do
      link = 'http://localhost:3000/'
      doc = filter("See #{link}")

      expect(doc.at_css('a').text).to eq link
      expect(doc.at_css('a')['href']).to eq link
    end

    it 'autolinks multiple URLs' do
      link1 = 'http://localhost:3000/'
      link2 = 'http://google.com/'

      doc = filter("See #{link1} and #{link2}")

      found_links = doc.css('a')

      expect(found_links.size).to eq(2)
      expect(found_links[0].text).to eq(link1)
      expect(found_links[0]['href']).to eq(link1)
      expect(found_links[1].text).to eq(link2)
      expect(found_links[1]['href']).to eq(link2)
    end

    it 'accepts link_attr options' do
      doc = filter("See #{link}", link_attr: { class: 'custom' })

      expect(doc.at_css('a')['class']).to eq 'custom'
    end

    it 'autolinks smb' do
      link = 'smb:///Volumes/shared/foo.pdf'
      doc = filter("See #{link}")

      expect(doc.at_css('a').text).to eq link
      expect(doc.at_css('a')['href']).to eq link
    end

    it 'autolinks multiple occurrences of smb' do
      link1 = 'smb:///Volumes/shared/foo.pdf'
      link2 = 'smb:///Volumes/shared/bar.pdf'

      doc = filter("See #{link1} and #{link2}")

      found_links = doc.css('a')

      expect(found_links.size).to eq(2)
      expect(found_links[0].text).to eq(link1)
      expect(found_links[0]['href']).to eq(link1)
      expect(found_links[1].text).to eq(link2)
      expect(found_links[1]['href']).to eq(link2)
    end

    it 'autolinks irc' do
      link = 'irc://irc.freenode.net/git'
      doc = filter("See #{link}")

      expect(doc.at_css('a').text).to eq link
      expect(doc.at_css('a')['href']).to eq link
    end

    it 'autolinks rdar' do
      link = 'rdar://localhost.com/blah'
      doc = filter("See #{link}")

      expect(doc.at_css('a').text).to eq link
      expect(doc.at_css('a')['href']).to eq link
    end

    it 'does not autolink javascript' do
      link = 'javascript://alert(document.cookie);'
      doc = filter("See #{link}")

      expect(doc.at_css('a')).to be_nil
    end

    it 'does not autolink bad URLs' do
      link = 'foo://23423:::asdf'
      doc = filter("See #{link}")

      expect(doc.to_s).to eq("See #{link}")
    end

    it 'does not autolink bad URLs after we remove trailing punctuation' do
      link = 'http://]'
      doc = filter("See #{link}")

      expect(doc.to_s).to eq("See #{link}")
    end

    it 'does not include trailing punctuation' do
      ['.', ', ok?', '...', '?', '!', ': is that ok?'].each do |trailing_punctuation|
        doc = filter("See #{link}#{trailing_punctuation}")
        expect(doc.at_css('a').text).to eq link
      end
    end

    it 'includes trailing punctuation when part of a balanced pair' do
      described_class::PUNCTUATION_PAIRS.each do |close, open|
        next if open.in?(quotes)

        balanced_link = "#{link}#{open}abc#{close}"
        balanced_actual = filter("See #{balanced_link}...")
        unbalanced_link = "#{link}#{close}"
        unbalanced_actual = filter("See #{unbalanced_link}...")

        expect(balanced_actual.at_css('a').text).to eq(balanced_link)
        expect(unescape(balanced_actual.to_html)).to eq(Rinku.auto_link("See #{balanced_link}..."))
        expect(unbalanced_actual.at_css('a').text).to eq(link)
        expect(unescape(unbalanced_actual.to_html)).to eq(Rinku.auto_link("See #{unbalanced_link}..."))
      end
    end

    it 'removes trailing quotes' do
      quotes.each do |quote|
        balanced_link = "#{link}#{quote}abc#{quote}"
        balanced_actual = filter("See #{balanced_link}...")
        unbalanced_link = "#{link}#{quote}"
        unbalanced_actual = filter("See #{unbalanced_link}...")

        expect(balanced_actual.at_css('a').text).to eq(balanced_link[0...-1])
        expect(unescape(balanced_actual.to_html)).to eq(Rinku.auto_link("See #{balanced_link}..."))
        expect(unbalanced_actual.at_css('a').text).to eq(link)
        expect(unescape(unbalanced_actual.to_html)).to eq(Rinku.auto_link("See #{unbalanced_link}..."))
      end
    end

    it 'removes one closing punctuation mark when the punctuation in the link is unbalanced' do
      complicated_link = "(#{link}(a'b[c'd]))'"
      expected_complicated_link = %Q{(<a href="#{link}(a'b[c'd]))">#{link}(a'b[c'd]))</a>'}
      actual = unescape(filter(complicated_link).to_html)

      expect(actual).to eq(Rinku.auto_link(complicated_link))
      expect(actual).to eq(expected_complicated_link)
    end

    it 'does not double-encode HTML entities' do
      encoded_link = "#{link}?foo=bar&amp;baz=quux"
      expected_encoded_link = %Q{<a href="#{encoded_link}">#{encoded_link}</a>}
      actual = unescape(filter(encoded_link).to_html)

      expect(actual).to eq(Rinku.auto_link(encoded_link))
      expect(actual).to eq(expected_encoded_link)
    end

    it 'does not include trailing HTML entities' do
      doc = filter("See &lt;&lt;&lt;#{link}&gt;&gt;&gt;")

      expect(doc.at_css('a')['href']).to eq link
      expect(doc.text).to eq "See <<<#{link}>>>"
    end

    it 'accepts link_attr options' do
      doc = filter("See #{link}", link_attr: { class: 'custom' })
      expect(doc.at_css('a')['class']).to eq 'custom'
    end

    it 'escapes RTLO and other characters' do
      # rendered text looks like "http://example.com/evilexe.mp3"
      evil_link = "#{link}evil\u202E3pm.exe"
      doc = filter("#{evil_link}")

      expect(doc.at_css('a')['href']).to eq "http://about.gitlab.com/evil%E2%80%AE3pm.exe"
    end

    it 'encodes international domains' do
      link     = "http://one😄two.com"
      expected = "http://one%F0%9F%98%84two.com"
      doc      = filter(link)

      expect(doc.at_css('a')['href']).to eq expected
    end

    described_class::IGNORE_PARENTS.each do |elem|
      it "ignores valid links contained inside '#{elem}' element" do
        exp = act = "<#{elem}>See #{link}</#{elem}>"
        expect(filter(act).to_html).to eq exp
      end
    end
  end

  context 'when the link is inside a tag' do
    %w[http rdar].each do |protocol|
      it "renders text after the link correctly for #{protocol}" do
        doc = filter(ERB::Util.html_escape_once("<#{protocol}://link><another>"))

        expect(doc.children.last.text).to include('<another>')
      end
    end
  end

  # Rinku does not escape these characters in HTML attributes, but content_tag
  # does. We don't care about that difference for these specs, though.
  def unescape(html)
    %w([ ] { }).each do |cgi_escape|
      html.sub!(CGI.escape(cgi_escape), cgi_escape)
    end

    quotes.each do |html_escape|
      html.sub!(CGI.escape_html(html_escape), html_escape)
      html.sub!(CGI.escape(html_escape), CGI.escape_html(html_escape))
    end

    html
  end
end
