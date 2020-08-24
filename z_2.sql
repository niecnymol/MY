wczesniej przygotowany plik statuses.csv zaimportowalem do bazy przy uzyciu programu dbeaver do bazy danych do tabeli kontakty tmp_kontakty

SELECT 
	klient_id,
	status
FROM 
	(
	SELECT 
		klient_id, --pobieram klient_id
		kontakt_ts, --pobieram kontakt_ts
		max(kontakt_ts) OVER (PARTITION BY klient_id) AS max_kontakt, --wyszukuje ostatni kontakt dla klienta
		count(kontakt_ts) OVER(PARTITION BY klient_id) AS liczba_kontaktow, --zliczam liczbe kontaktow dla klienta
		status --pobieram status
	FROM 
		tmp_kontakty
	) foo --tworze podzapytanie
WHERE 
	foo.max_kontakt = foo.kontakt_ts --wybieram tylko ostatnie kontakty na klientow porownujac kontakt_ts z max(kontakt_ts) na kliencie
	AND foo.liczba_kontaktow >= 3  --pobieram tylko tych klientow, gdzie liczba kontaktow jest wieksza lub rowna 3