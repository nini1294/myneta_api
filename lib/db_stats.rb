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
    puts "Members of Parliament (MPs):"

    mp_count = MP.count
    mp_years = MP.select_map(:year).uniq.sort

    puts "  Total MPs (across all years): #{format_number(mp_count)}"

    return if mp_years.empty?

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

    puts
    puts "  Top 10 States by MLAs:"
    MLA.select_group(:state).
         select_append { [Sequel.lit('COUNT(*)').as(:mla_count)] }.
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
