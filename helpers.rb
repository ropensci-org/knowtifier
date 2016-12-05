def time_since(x)
  z = Time.now.getutc - x
  return (z / 3600).floor
end
