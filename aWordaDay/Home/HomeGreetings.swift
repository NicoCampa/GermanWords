//
//  HomeGreetings.swift
//  aWordaDay
//
//  Extracted from ContentView.swift
//

import SwiftUI

extension ContentView {
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let minute = Calendar.current.component(.minute, from: Date())
        let day = Calendar.current.component(.day, from: Date())
        let seedValue = (day * 100 + minute / 10)

        switch hour {
        case 5..<12:
            let morningGreetings = [
                "☀️ Guten Morgen! Neues Wort, neuer Tag.",
                "Moin moin aus Hamburg – bereit?",
                "Kaffee, Brötchen, Grammatik?",
                "Alpenluft im Kopf, Vokabel im Herzen.",
                "Grüße vom Bodensee, los geht's!",
                "Berliner Morgenbrise + Wort des Tages.",
                "Frisch wie der Schwarzwaldtau?",
                "Zeit für ein frisches Brötchen und ein frisches Wort.",
                "Sauerteig, Sonnenschein, Substantive.",
                "Bahnsteig voller Pendler, Kopf voller Fälle."
            ]
            return morningGreetings[seedValue % morningGreetings.count]

        case 12..<17:
            let afternoonGreetings = [
                "Servus aus München – weiter üben!",
                "Zwischendurch ein Wort wie eine Breze.",
                "Kaffee und Konjunktiv gefällig?",
                "Currywurst-Pause? Nimm ein neues Wort.",
                "Feines Wetter am Rhein, perfekte Lernzeit.",
                "Südtiroler Sonne, deutsche Fälle.",
                "Grüße aus Frankfurt – Kasus-Check!",
                "Zeit für eine Vokabelwanderung.",
                "Berliner Späti-Vibes, mittags gelernt.",
                "Zwischen Meeting und Mittag: Grammatik."
            ]
            return afternoonGreetings[seedValue % afternoonGreetings.count]

        case 17..<22:
            let eveningGreetings = [
                "Feierabend im Blick, aber erst ein Wort.",
                "Abendgrüße von der Elbe.",
                "Sonnenuntergang + Substantive = ❤️",
                "Nach der Arbeit kommt der Akkusativ.",
                "Kerzenschein und Komposita.",
                "Dom-Lichter, Dativ-Drills.",
                "Rheingold-Stimmung, Grammatik inklusive.",
                "Gemütlicher Abend? Mach ihn sprachreich.",
                "Spreeblick und Perfektformen.",
                "Noch ein Wort, dann Sofa."
            ]
            return eveningGreetings[seedValue % eveningGreetings.count]

        default:
            let lateNightGreetings = [
                "Nachtschicht in Berlin – weiter so!",
                "Nordseewind und Mitternachtsgrammatik.",
                "Oktoberfestträume und Perfektformen.",
                "Sterne über dem Harz, Wörter im Kopf.",
                "Kölner Lichter, leises Lernen.",
                "Wenn die Stadt schläft, übst du Fälle.",
                "Mitternachts-Bahn + neue Verben.",
                "Nachts ist der Genitiv wach.",
                "Mondlicht auf dem Rhein, Satzbau im Sinn.",
                "Quietschende Straßenbahn, fokussierter Geist."
            ]
            return lateNightGreetings[seedValue % lateNightGreetings.count]
        }
    }

}
