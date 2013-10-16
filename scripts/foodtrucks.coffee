# Description:
#   Get a list of foodtrucks in your area (currently, only Boston). Instead of
#   sending a command, you visit a URL:
#   http://ralph-hubot.herokuapp.com/foodtrucks
#
# Dependencies:
#   cheerio
#   strftime
#   sprintf
#   underscore
#
# Configuration:
#   None
#
# URLs:
#   /foodtrucks - See food trucks in your area

strftime = require 'strftime'
cheerio = require 'cheerio'
sprintf = require('sprintf').sprintf
_ = require 'underscore'

class FoodTruck
  NO_FOOD_TRUCKS = 'No food trucks near the office now.'

  constructor: (html) ->
    @$ = cheerio.load(html)
    @doc = @$('.trFoodTrucks')

  all: ->
    availableTrucks = @allAvailable()
    if availableTrucks.length == 0
      NO_FOOD_TRUCKS
    else
      byNameLength = (a, b) ->
        a.name().length - b.name().length

      byLocation = (a, b) ->
        location = a.location()
        otherLocation = b.location()
        if location < otherLocation
          -1
        else if location > otherLocation
          1
        else
          0

      longestTruckNameLength = availableTrucks.sort(byNameLength).slice(-1)[0].name().length
      "Lunch trucks:\n" + availableTrucks.sort(byLocation).map((truck) ->
        truck.prettyInformation(longestTruckNameLength)
      ).join("\n")

  allAvailable: ->
    mapped = @doc.map (i, element) =>
      new Truck(@$(element))
    _.filter(mapped, (truck) -> truck.available())

class Truck
  NEAR_OFFICE = /Financial|(South Station)|Greenway|(City Hall)|(Dewey Square)|(Boston Common)|Chinatown/
  TIME_OF_DAY = 'Lunch'

  constructor: (element) ->
    @element = element

  available: ->
    @dayIsToday() and @timeIsNow() and @isNearOffice()

  prettyInformation: (justification) ->
    sprintf "%-#{justification}s @ %s", @name(), @location()

  name: ->
    name = @find('.com a').text()
    NormalizedTruckName.normalize(name)

  location: ->
    machineLocation = @find('.loc').text().split(';').slice(-1)[0]
    HumanLocation.normalize(machineLocation)

  dayIsToday: ->
    @find('.dow').text() == @dayOfWeek()

  timeIsNow: ->
    @find('.tod').text() == TIME_OF_DAY

  isNearOffice: ->
    @find('.loc').text().match(NEAR_OFFICE)

  find: (selector) ->
    @element.find(selector)

  dayOfWeek: ->
    strftime('%A', new Date())

class HumanLocation
  MAP =
    'Boston Common, Brewer Fountain by Tremont and Boylston Streets': 'Boston Common'
    'Rose Kennedy Greenway, Dewey Square, South Station': 'South Station plaza (walk up Summer St towards DTX)'
    'Financial District, Milk and Kilby Streets': 'Milk & Kilby (left on Washington, right on Milk, go past the park)'
    'Chinatown/Park Street, Boylston St near Washington St': 'Chinatown Station (right on Washington until Boylston)'

  @normalize: (lessHumanLocation) ->
    cleaned = lessHumanLocation.
      replace(/^\(\d+\) /, '').
      replace('Greenway,Congress', 'Greenway, Congress')
    MAP[cleaned] || cleaned

class NormalizedTruckName
  @normalize: (truckName) ->
    truckName.
      replace(/[A-Z]{3}$/, '').
      replace(/\d$/, '').
      replace(/^ +/, '').
      replace(/\ +$/, '')

module.exports = (robot) ->
  path = "/foodtrucks"

  robot.respond /foodtrucks/i, (msg) ->
    newUrl = process.env.HEROKU_URL + path
    msg.send "To avoid clutter, this is now a URL instead of a command. Visit " + newUrl

  robot.router.get path, (req, res) ->
    URL = 'http://www.cityofboston.gov/business/mobile/schedule-app-min.asp'

    robot.http(URL).get() (err, r, body) ->
      foodTruck = new FoodTruck(body)
      all = foodTruck.all()
      res.end all
