module Main exposing (Model, Msg(..), init, main, subscriptions, timeline, timelineEnd, timelineList, timelineStart, update, view)

import Browser
import Browser.Dom
import Browser.Events
import Browser.Navigation as Nav
import Dict
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
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    (Model key url 0, Task.perform InitialViewport Browser.Dom.getViewport )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | Resized Int Int
    | InitialViewport Browser.Dom.Viewport

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

        InitialViewport viewport ->
            ( { model | width = truncate viewport.viewport.width }, Cmd.none)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onResize Resized



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Copala"
    , body =
        [ img [ src "copala.svg" ] []
        , h2 [] [ text "northside's student-run play festival" ]
        , timeline model.width
        , h3 [] [ text "currently: plays!" ]
        , p [] [ text "Copala is all about creativity and weirdness. Your play can can cover any topic and doesn’t have to even resemble a play -- just keep it school appropriate. The length is capped at 30 minutes, and you can make use of the lights, curten, and props." ]
        , a [ class "d-flex button", href "asd" ] [ text "submit a play" ]
        ]
    }


timelineList = Dict.fromList [ ( "plays due", 1553922000 ), ( "3-5 announced", 1554267600 ), ( "tryouts", 1554699600 ), ( "Copala", 1558674000 ) ]
timelineStart = 1551398400
timelineEnd = 1559347200
timelineWidth = 0.7

timeline : Int -> Html Msg
timeline width =
    let
        posixToPercent =
            \posix -> (posix - timelineStart) / (timelineEnd - timelineStart)

        posixToPosition =
            posixToPercent >> (*) (width |> toFloat |> (*) timelineWidth) >> String.fromFloat >> (\s -> s ++ "px")

        posixToDay =
            truncate >> Time.millisToPosix >> Time.toDay Time.utc
    in
    div [ class "" ]
        (timelineList
            |> Dict.map
                (\name posix ->
                    div
                        [ class "position-absolute"
                        , style "left" <| posixToPosition posix
                        ]
                        [ h4 [] [ text name ]
                        , p [] [ text (String.fromInt (posixToDay posix)) ]
                        ]
                )
            |> Dict.values
        )
