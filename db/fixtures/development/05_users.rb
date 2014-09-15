Gitlab::Seeder.quiet do
  (2..20).each  do |i|
    begin
      User.seed(:id, [{
        id: i,
        username: Faker::Internet.user_name,
        name: Faker::Name.name,
        email: Faker::Internet.email,
        confirmed_at: DateTime.now
      }])
      print '.'
    rescue ActiveRecord::RecordNotSaved
      print 'F'
    end
  end

  (1..5).each do |i|
    begin
      User.seed(:id, [
        id: i + 10,
        username: "user#{i}",
        name: "User #{i}",
        email: "user#{i}@example.com",
        confirmed_at: DateTime.now,
        password: '12345678'
      ])
      print '.'
    rescue ActiveRecord::RecordNotSaved
      print 'F'
    end
  end
end
