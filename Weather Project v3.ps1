###WEATHER### 
Function Get-Weather(){
    
    #Parameters for function properties
    Param (
        [Parameter(Position=0,mandatory=$true)]
        [ValidateNotNull()]
        [string]$location,
        [Parameter(Position=1,mandatory=$true)]
        [ValidateRange(0,8)]
        [int]$days,
        [Parameter(Position=2,mandatory=$true)]
        [ValidateSet("F","C")]
        [string]$units
        )
        
    #API Keys
    $weatherKey =  "" #Insert API key here
    $googleKey  =  "" #Insert API key here

    #Weather URL Functionality for excluding data and unit placeholders
    $exclude = "?exclude=flags,hourly,minutely,alerts,currently"
    $celsius = ""
    $wind = ""
    $precip = ""

    #Placeholder for unix conversions
    $unixDate = get-date "1/1/1970"

    #Get and display lat/long for the given location using Geocoding and rounding values. This is used for weather API URL
    $geoCodeServer = (curl -method get -Uri "https://maps.googleapis.com/maps/api/geocode/json?address=$Location&key=$GoogleKey" | ConvertFrom-Json)
    $lat = $geoCodeServer.Results.geometry.location.lat[0]
    $lon = $geoCodeServer.Results.geometry.location.lng[0]
    $lat = [math]::Round($lat)
    $lon = [math]::Round($lon)
    Write-Host "LAT: $lat"
    Write-Host "LONG: $lon"

    #Celsius/Farenheit Logic to add into weather API URL
    #Final output tags
    If($units.ToUpper() -match "C"){ # Celsius
        $celsius = "&units=si"
        $wind = "m/s"
        $precip = "cm."
        }
    If($Units.ToUpper() -match "F"){ # Farenheit
        $celsius = "&units=us"
        $wind = "mph"
        $precip = "in."
        }
        
    #Get weather data from lat/long, exclusion, and unit information
    $Weather = (curl "https://api.darksky.net/forecast/$weatherKey/$lat,$lon$exclude$celsius" | ConvertFrom-JSON)
        
    #DISPLAY FUTURE WEATHER LOOP
    for($i=0;$i -le $days; $i++){
       
        #Get weather for the day that the loop is in   
        $weatherForecastFinal = $weather.daily.data[$i]

        #Convert the day's UNIX time to readable format
        $futureDateReadable = $unixDate.addseconds($weatherForecastFinal.time)

        #Create Object for formatting on output, round some to nearest whole number
        $future = New-object PSObject -property ([Ordered]@{
            "Time (Local)" = $futureDateReadable.ToString("MMM dd, yyyy (dddd)")
            "Conditions" = $weatherForecastFinal.summary
            "High ($units)" = [math]::Round($weatherForecastFinal.temperatureHigh)
            "Low ($units)" = [math]::Round($weatherForecastFinal.temperatureLow)
            "Humidity (%)" = [math]::Round(($weatherForecastFinal.humidity) * 100)
            "Snow ($precip)" = if([string]::IsNullOrEmpty($weatherForecastFinal.precipAccumulation)){ #Test to make sure this has a value, if not; return 0
                                [int] 0
                                }
                            Else{
                                $weatherForecastFinal.precipAccumulation}                           
            "Rain ($precip)" = if([string]::IsNullOrEmpty($weatherForecastFinal.precipIntensity)){ #Test to make sure this has a value, if not; return 0
                                [int] 0
                                }
                            Else{
                                $weatherForecastFinal.precipIntensity}       
            "Wind ($wind)" = [math]::Round($weatherForecastFinal.windSpeed)
            "Gust ($wind)" = [math]::Round($weatherForecastFinal.windGust)
        })
               
        #Final Object
        $future
    } 

    #Reset location and weather variables
    $weather = ""
}
