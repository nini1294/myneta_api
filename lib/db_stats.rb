require_relative '../models.rb'

class DbStats
  def self.run
    puts "=" * 50
    puts "DATABASE STATISTICS"
    puts "=" * 50
    puts

    print_mp_stats
    print_mla_stats

    puts
    puts "=" * 50
  end

  def self.print_mp_stats
    mp_count = MP.count
    expected_total = 543  # Total Lok Sabha seats
    puts "Members of Parliament (MPs):"
    puts "  Total MPs: #{format_number(mp_count)}/#{format_number(expected_total)}"

    return if mp_count == 0

    mp_years = MP.select_map(:year).uniq.sort
    puts "  Years scraped: #{mp_years.join(', ')}"
    puts
    puts "  By Year:"
    mp_years.each do |year|
      count = MP.filter(year: year).count
      puts "    #{year}: #{format_number(count)} MPs"
    end
    puts
  end

  def self.print_mla_stats
    mla_count = MLA.count
    puts "Members of Legislative Assembly (MLAs):"
    puts "  Total MLAs: #{format_number(mla_count)}"

    return if mla_count == 0

    mla_states = MLA.select_map(:state).uniq.sort
    puts "  States scraped: #{mla_states.join(', ')}"
    puts
    puts "  Top 10 States by MLAs:"
    MLA.select_group(:state).
         select { [state, count.as(:mla_count)] }.
         order(Sequel.desc(:mla_count)).
         limit(10).
         each do |row|
      puts "    #{row[:state]}: #{format_number(row[:mla_count])}"
    end
    puts
  end

  def self.format_number(num)
    num.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
