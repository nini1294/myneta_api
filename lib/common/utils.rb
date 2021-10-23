class Utils
  def self.format_state(state)
    state = state.capitalize.gsub(/(_| )./) {|match| ' ' + match[1].capitalize}
    state.gsub(/&/, 'And')
  end

  def self.unformat_state(state)
      state.downcase.gsub(/ /, '_')
  end
end