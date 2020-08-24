--tworze tabele 
CREATE TABLE f_docieralnosc(
	"data" date,
	sukcesy int,
	utraty int,
	do_ponowienia int,
	zainteresowani_utraty int,
	niezainteresowani_sukcesy int
)


INSERT INTO f_docieralnosc (
	"data",
	sukcesy,
	utraty,
	do_ponowienia,
	zainteresowani_utraty,
	niezainteresowani_sukcesy)	
SELECT 
	data_kontakt,
	SUM(sukcesy) AS sukcesy,   -- w podzapytaniu grupuje po parze klient_id-kontakt_ts, wiec w przypadku wiekszej liczby kontaktow w ciagu dnia niz 1 na tego samego klienta, 
	SUM(utraty) AS utraty,     -- potrzebuje zsumowac wyniki
	SUM(do_ponowienia) AS do_ponowienia,
	SUM(zainteresowani_utraty) AS zainteresowani_utraty,
	SUM(niezainteresowani_sukcesy) AS niezainteresowani_sukcesy
FROM (
	SELECT 
		date(kontakt_ts) AS data_kontakt, --konwertuje kontakt_ts z timestamp na data
		CASE 
			WHEN LAST_VALUE(status) OVER (PARTITION BY klient_id, date(kontakt_ts) ORDER BY kontakt_ts DESC RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) LIKE 'zainteresowany' THEN 1
		END AS sukcesy, --pobieram ostatni status 'zainteresowy' dla pary klient-data sortujac malejaco po kontakt_ts
		CASE 
			WHEN LAST_VALUE(status) OVER (PARTITION BY klient_id, date(kontakt_ts) ORDER BY kontakt_ts DESC RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) LIKE 'niezainteresowany' THEN 1
		END AS utraty, --pobieram ostatni status 'niezainteresowany' dla pary klient-data sortujac malejaco po kontakt_ts
		CASE 
			WHEN LAST_VALUE(status) OVER (PARTITION BY klient_id, date(kontakt_ts) ORDER BY kontakt_ts DESC RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) LIKE 'poczta_glosowa'
			OR LAST_VALUE(status) OVER (PARTITION BY klient_id, date(kontakt_ts) ORDER BY kontakt_ts DESC RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) LIKE 'nie_ma_w_domu' THEN 1
		END AS do_ponowienia, --pobieram ostatni status 'poczta_glosowa' lub 'nie_ma_w_domu' dla pary klient-data sortujac malejaco po kontakt_ts
		CASE 
			WHEN LAG(status) OVER (PARTITION BY klient_id ORDER BY kontakt_ts) LIKE 'zainteresowany' AND 
				LAST_VALUE(status) OVER (PARTITION BY klient_id ORDER BY kontakt_id DESC RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) = 'niezainteresowany'
				THEN 1
		END AS zainteresowani_utraty, --pobieram i porownuje dwa ostatnie statusy dla klienta
		CASE 
			WHEN LAG(status) OVER (PARTITION BY klient_id ORDER BY kontakt_ts) LIKE 'niezainteresowany' AND 
				LAST_VALUE(status) OVER (PARTITION BY klient_id ORDER BY kontakt_id DESC RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) = 'zainteresowany'
				THEN 1
		END AS niezainteresowani_sukcesy --pobieram i porownuje dwa ostatnie statusy dla klienta
	FROM 
		tmp_kontakty
	) foo  --tworze podzapytanie
GROUP BY 1 --grupuje i sortuje po kolumnie 'data'
ORDER BY 1;
