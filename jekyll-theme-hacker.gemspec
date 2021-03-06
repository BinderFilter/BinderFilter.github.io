# encoding: utf-8

Gem::Specification.new do |s|
  s.name          = "jekyll-theme-hacker"
  s.version       = "0.0.3"
  s.license       = "CC0-1.0"
  s.authors       = ["Jason Costello", "GitHub, Inc."]
  s.email         = ["opensource+jekyll-theme-hacker@github.com"]
  s.homepage      = "https://github.com/pages-themes/hacker"
  s.summary       = "Hacker is a Jekyll theme for GitHub Pages"

  s.files         = `git ls-files -z`.split("\x0").select do |f|
    f.match(%r{^((_layouts|assets)/|(LICENSE)((\.(txt|md|markdown)|$)))}i)
  end

  s.platform      = Gem::Platform::RUBY
  s.add_runtime_dependency "jekyll", "~> 3.3"
end
