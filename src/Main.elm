module Main exposing (Model, Msg(..), init, main, subscriptions, timeline, timelineEnd, timelineList, timelineStart, update, view)

import Browser
import Browser.Dom
import Browser.Events
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task
import Time
import Url



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , width : Int
    , now : Int
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    (Model key url 0 0, Task.perform identity (Task.map2 InitialData Browser.Dom.getViewport Time.now ))



-- UPDATE


type Msg = LinkClicked Browser.UrlRequest | UrlChanged Url.Url | Resized Int Int
    | InitialData Browser.Dom.Viewport Time.Posix

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | url = url }, Cmd.none )

        Resized width height ->
            ( { model | width = width }, Cmd.none )

        InitialData viewport now ->
            ( { model | width = truncate viewport.viewport.width, now = (Time.posixToMillis now) // 1000}, Cmd.none)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onResize Resized



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Copala"
    , body =
        [div [class "py-9 w-100 text-center"]
            [ img [ src "img/copala.svg", class "mx-auto" ] []
            , h2 [ class "mt-5 mb-9" ] [ text "northside's student-run play festival" ]
            , timeline model.width model.now
            , h3 [ class "mt-9" ] [ text "currently: plays!" ]
            , p [ class "w-75 mx-auto mt-3 mb-5 text-left"
                , style "max-width" "1000px"
            ] [ text "Copala is all about creativity and weirdness. Your play can can cover any topic and doesn’t have to even resemble a play -- just keep it school appropriate. The length should be 15-30 pages, and you can make use of the lights, curtain, and props." ]
            , a [ class "button mx-auto", href "https://goo.gl/forms/WOlsLFdPWgRyjiFm1" ] [ text "submit a play" ]
            ]
        ]
    }


timelineList = [ ( "plays", 1553922000 ), ( "3-5 announced", 1554267600 ), ( "tryouts", 1554699600 ), ( "Copala", 1558674000 ) ]
timelineStart = 1552398400
timelineEnd = 1558694000
timelineWidth = 0.7

toMonth : Time.Month -> String
toMonth month =
  case month of
    Time.Jan -> "January"
    Time.Feb -> "February"
    Time.Mar -> "March"
    Time.Apr -> "April"
    Time.May -> "May"
    Time.Jun -> "June"
    Time.Jul -> "July"
    Time.Aug -> "August"
    Time.Sep -> "September"
    Time.Oct -> "October"
    Time.Nov -> "November"
    Time.Dec -> "December"

timeline : Int -> Int -> Html Msg
timeline width now =
    let
        posixToPercent =
            \posix -> (posix - timelineStart) / (timelineEnd - timelineStart)

        posixToPosition =
            posixToPercent >> (*) (width |> toFloat |> (*) timelineWidth) >> String.fromFloat >> (\s -> s ++ "px")

        posixToString = \posix ->
            let truePosix = posix |> truncate |> (*) 1000 |> Time.millisToPosix
            in
            (toMonth <| Time.toMonth Time.utc truePosix) ++ " " ++
            (String.fromInt <| Time.toDay Time.utc truePosix)
    in
    div [class "timeline"]
        <| [div [class "timeline-bar"] []] ++ (
            timelineList
            |> (::) ("now", (toFloat now))
            |> List.sortBy Tuple.second
            |> List.map
                (\(name, posix) ->
                    div
                        [ class "timeline-section"
                        , class (if name == "now" then "now" else "date")
                        , style "left" <| posixToPosition posix
                        ]
                        [ div [ class "timeline-text"
                              , class (if name == "3-5 announced" || name == "now" then "top" else "bottom")
                              ]
                          [ p [ class "timeline-heading" ] [ text name ]
                          , p [ class "timeline-date" ] [ text (posixToString posix) ]
                          ]
                        ]
                )
        )

