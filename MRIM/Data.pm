#
# $Date: 2008-01-05 12:12:42 $
#
# Copyright (c) 2007-2008 Alexandre Aufrere
# Licensed under the terms of the GPL (see perldoc MRIM.pm)
#

use 5.008;
use strict;

package Net::MRIM::Data;

=pod

=head1 NAME

Net::MRIM::Data - Optional data for MRIM Protocol

=head1 DESCRIPTION

Contains country codes from http://agent.mail.ru/region.txt

=head1 AUTHOR

Alexandre Aufrere <aau@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007-2008 Alexandre Aufrere. This code may be used under the terms of the GPL version 2 (see at http://www.gnu.org/licenses/old-licenses/gpl-2.0.html). The protocol remains the property of Mail.Ru (see at http://www.mail.ru).

=cut

use utf8;

our %COUNTRIES= (
'Россия'=>'24',
'Россия,Дальневосточный ФО'=>'24',
'Азия,Азербайджан'=>'81',
'Азия,Армения'=>'82',
'Азия,Афганистан'=>'97',
'Азия,Бангладеш'=>'96',
'Азия,Бахрейн'=>'99',
'Азия,Бруней-Даруссалам'=>'100',
'Азия,Бутан'=>'101',
'Азия,Вьетнам'=>'102',
'Азия,Грузия'=>'83',
'Азия,Израиль'=>'86',
'Азия,Индия'=>'95',
'Азия,Индонезия'=>'103',
'Азия,Иордания'=>'79',
'Азия,Ирак'=>'85',
'Азия,Иран'=>'87',
'Азия,Йемен'=>'104',
'Азия,Казахстан'=>'84',
'Азия,Камбоджа'=>'105',
'Азия,Катар'=>'106',
'Азия,Кипр'=>'107',
'Азия,Киргизия (Кыргызстан)'=>'92',
'Азия,Китай'=>'76',
'Азия,Кокосовые острова (Австр.)'=>'3215',
'Азия,Корея (КНДР)'=>'29',
'Азия,Корея, Республика'=>'108',
'Азия,Кувейт'=>'88',
'Азия,Лаос'=>'109',
'Азия,Ливан'=>'110',
'Азия,Малайзия'=>'111',
'Азия,Мальдивы'=>'112',
'Азия,Монголия'=>'113',
'Азия,Мьянма'=>'114',
'Азия,Непал'=>'115',
'Азия,Объединенные Арабские Эмираты'=>'116',
'Азия,Оман'=>'117',
'Азия,Остров Рождества (Австр.)'=>'3216',
'Азия,Пакистан'=>'122',
'Азия,Палестина'=>'89',
'Азия,Саудовская Аравия'=>'94',
'Азия,Сингапур'=>'118',
'Азия,Сирия'=>'78',
'Азия,Таджикистан'=>'91',
'Азия,Таиланд'=>'119',
'Азия,Тайвань'=>'120',
'Азия,Тимор'=>'132',
'Азия,Туркмения'=>'90',
'Азия,Турция'=>'77',
'Азия,Узбекистан'=>'93',
'Азия,Филиппины'=>'121',
'Азия,Шри Ланка'=>'98',
'Азия,Япония'=>'75',
'Австралия и Океания,Австралия'=>'123',
'Австралия и Океания,Американское Самоа'=>'454',
'Австралия и Океания,Вануату'=>'124',
'Австралия и Океания,Гуам (США)'=>'453',
'Австралия и Океания,Кирибати'=>'126',
'Австралия и Океания,Маршалловы Острова'=>'127',
'Австралия и Океания,Микронезия (Федеративные Штаты Микронезии)'=>'128',
'Австралия и Океания,Науру'=>'129',
'Австралия и Океания,Ниуэ (Н.Зел.)'=>'3220',
'Австралия и Океания,Новая Зеландия'=>'130',
'Австралия и Океания,Новая Каледония (Фр.)'=>'3218',
'Австралия и Океания,Острова Кука (Н.Зел.)'=>'3221',
'Австралия и Океания,Острова Херд и Макдональд (Австр.)'=>'3230',
'Австралия и Океания,Палау'=>'131',
'Австралия и Океания,Папуа - Новая Гвинея'=>'133',
'Австралия и Океания,Питкерн (Брит.)'=>'3222',
'Австралия и Океания,Самоа'=>'125',
'Австралия и Океания,Сев. Марианские острова (США)'=>'3219',
'Австралия и Океания,Соломоновы Острова'=>'134',
'Австралия и Океания,Токелау (Н.Зел.)'=>'3223',
'Австралия и Океания,Тонга'=>'135',
'Австралия и Океания,Тувалу'=>'136',
'Австралия и Океания,Уоллис и Футуна острова (Фр.)'=>'3224',
'Австралия и Океания,Фиджи'=>'137',
'Австралия и Океания,Французская Полинезия'=>'3226',
'Австралия и Океания,Французские Южные территории'=>'3225',
'Америка,Канада'=>'138',
'Америка,США'=>'139',
'Америка,Ангилья (Брит.)'=>'3200',
'Америка,Антигуа и Барбуда'=>'140',
'Америка,Аргентина'=>'141',
'Америка,Аруба (Нид.)'=>'3202',
'Америка,Багамы'=>'142',
'Америка,Барбадос'=>'143',
'Америка,Белиз'=>'146',
'Америка,Бермуды (Брит.)'=>'3203',
'Америка,Боливия'=>'144',
'Америка,Бразилия'=>'145',
'Америка,Венесуэла'=>'147',
'Америка,Виргинские острова (Брит.)'=>'3204',
'Америка,Виргинские острова (США)'=>'452',
'Америка,Гаити'=>'149',
'Америка,Гайана'=>'148',
'Америка,Гваделупа (Фр.)'=>'3205',
'Америка,Гватемала'=>'173',
'Америка,Гондурас'=>'150',
'Америка,Гренада'=>'151',
'Америка,Гренландия (Дат.)'=>'152',
'Америка,Доминика'=>'153',
'Америка,Доминиканская Республика'=>'154',
'Америка,Колумбия'=>'155',
'Америка,Коста-Рика'=>'156',
'Америка,Куба'=>'157',
'Америка,Мартиника (Фр.)'=>'3208',
'Америка,Мексика'=>'158',
'Америка,Монтсеррат (Брит)'=>'3209',
'Америка,Нидерландские Антилы'=>'3201',
'Америка,Никарагуа'=>'159',
'Америка,Остров Кайман (Брит.)'=>'3207',
'Америка,Острова Теркс и Кайкос (Брит.)'=>'3211',
'Америка,Панама'=>'160',
'Америка,Парагвай'=>'161',
'Америка,Перу'=>'162',
'Америка,Сальвадор'=>'163',
'Америка,Сент-Винсент и Гренадины'=>'164',
'Америка,Сент-Китс и Невис'=>'165',
'Америка,Сент-Люсия'=>'166',
'Америка,Сент-Пьер и Микелон (Фр.)'=>'3210',
'Америка,Суринам'=>'167',
'Америка,Тринидат и Тобаго'=>'168',
'Америка,Уругвай'=>'169',
'Америка,Фолклендские острова (Брит.)'=>'3212',
'Америка,Французская Гвиана'=>'3206',
'Америка,Чили'=>'170',
'Америка,Эквадор'=>'171',
'Америка,Юж. Джорджия и Юж. Сандвичевы о-ва (Брит.)'=>'3213',
'Америка,Ямайка'=>'172',
'Африка,Алжир'=>'174',
'Африка,Ангола'=>'175',
'Африка,Бенин'=>'176',
'Африка,Ботсвана'=>'177',
'Африка,Британская территория в Индийском океане'=>'3228',
'Африка,Буркина-Фасо'=>'178',
'Африка,Бурунди'=>'179',
'Африка,Габон'=>'180',
'Африка,Гамбия'=>'181',
'Африка,Гана'=>'182',
'Африка,Гвинея'=>'183',
'Африка,Гвинея-Бисау'=>'184',
'Африка,Джибути'=>'185',
'Африка,Египет'=>'186',
'Африка,Замбия'=>'187',
'Африка,Зап. Сахара'=>'3198',
'Африка,Зимбабве'=>'23',
'Африка,Кабо-Верде'=>'188',
'Африка,Камерун'=>'189',
'Африка,Кения'=>'190',
'Африка,Коморы'=>'191',
'Африка,Конго (Заир)'=>'193',
'Африка,Конго, Республика'=>'192',
'Африка,Кот-д`Ивуар'=>'194',
'Африка,Лесото'=>'195',
'Африка,Либерия'=>'196',
'Африка,Ливия'=>'197',
'Африка,Маврикий'=>'198',
'Африка,Мавритания'=>'199',
'Африка,Мадагаскар'=>'200',
'Африка,Майотт (Фр.)'=>'3229',
'Африка,Малави'=>'201',
'Африка,Мали'=>'202',
'Африка,Марокко'=>'203',
'Африка,Мозамбик'=>'204',
'Африка,Намибия'=>'205',
'Африка,Нигер'=>'206',
'Африка,Нигерия'=>'207',
'Африка,Остров Буве (Норв.)'=>'3227',
'Африка,Реюньон (Фр.)'=>'3197',
'Африка,Руанда'=>'208',
'Африка,Сан-Томе и Принсипи'=>'209',
'Африка,Свазиленд'=>'210',
'Африка,Святая Елена (Брит.)'=>'3199',
'Африка,Сейшелы'=>'211',
'Африка,Сенегал'=>'212',
'Африка,Сомали'=>'213',
'Африка,Судан'=>'214',
'Африка,Сьерра-Леоне'=>'215',
'Африка,Танзания'=>'216',
'Африка,Того'=>'217',
'Африка,Тунис'=>'218',
'Африка,Уганда'=>'219',
'Африка,Центральноафриканская Республика'=>'220',
'Африка,Чад'=>'222',
'Африка,Экваториальная Гвинея'=>'223',
'Африка,Эритрея'=>'221',
'Африка,Эфиопия'=>'224',
'Африка,Южно-Африканская Республика (ЮАР)'=>'225',
'Европа,Украина'=>'39',
'Европа,Австрия'=>'40',
'Европа,Албания'=>'32',
'Европа,Андорра'=>'33',
'Европа,Белоруссия'=>'340',
'Европа,Бельгия'=>'38',
'Европа,Болгария'=>'41',
'Европа,Босния и Герцеговина'=>'42',
'Европа,Ватикан'=>'43',
'Европа,Великобритания'=>'45',
'Европа,Венгрия'=>'44',
'Европа,Германия'=>'46',
'Европа,Гернси (Брит.)'=>'3193',
'Европа,Гибралтар (Брит.)'=>'47',
'Европа,Греция'=>'48',
'Европа,Дания'=>'49',
'Европа,Джерси (Брит.)'=>'3194',
'Европа,Ирландия'=>'50',
'Европа,Исландия'=>'51',
'Европа,Испания'=>'34',
'Европа,Италия'=>'52',
'Европа,Латвия'=>'53',
'Европа,Литва'=>'54',
'Европа,Лихтенштейн'=>'55',
'Европа,Люксембург'=>'56',
'Европа,Македония'=>'57',
'Европа,Мальта'=>'58',
'Европа,Молдавия'=>'59',
'Европа,Монако'=>'36',
'Европа,Нидерланды'=>'60',
'Европа,Норвегия'=>'61',
'Европа,Остров Мэн (Брит.)'=>'3195',
'Европа,Польша'=>'62',
'Европа,Португалия'=>'35',
'Европа,Румыния'=>'63',
'Европа,Сан-Марино'=>'64',
'Европа,Сербия и Черногория'=>'74',
'Европа,Словакия'=>'65',
'Европа,Словения'=>'66',
'Европа,Фарерские о-ва (Дания)'=>'67',
'Европа,Финляндия'=>'68',
'Европа,Франция'=>'37',
'Европа,Хорватия'=>'69',
'Европа,Чехия'=>'70',
'Европа,Швейцария'=>'71',
'Европа,Швеция'=>'72',
'Европа,Шпицберген (Норв.)'=>'3196',
'Европа,Эстония'=>'73'
);

1;