## KOMPILERING 
#=================================================================
För att börja behöver du skapa en fil med filändelsen
.bl där du kan skriva ditt program. När du har skrivit ett program så använder du runbl.rb för att kompilera och köra koden.

    $ ./runbl.rb <flaggor> <program>

Program byter du ut mot din fil som har filändelsen .bl och du kan använda vilken kombination du vill av
nedanstående flaggor.

    -debug Debug-utskrifter för parsern
    -tree Skriver ut hela programmet i en trädstruktur
    -norun Stänger av körning av programmet


## Datayper 
#=======
    - int 
    - float 
    - bool 
    - list 
    - string
    - char 


## Variabler
#=======
    Exempel: 

    int x;
    list <float> l;
    x = 5;
    x = int y = 7


## Print
#=======
    Exempel: 

    int x = 5;
    print x;
    print;
    print 123;
    -> 5
    ->
    ->12


## Loopar
#=======

    - for(initiering; villkor; steg)
    - while(villkor)
    - break 
    - continue 

    Exempel: 
    for (int y = 0; y < 5; y = y+1)
    {
        if (y == 3) begin
        print 1337;
        end
    }

    int x = 0;
    while ( x < 5 )
    { 
    x = x+1 + (x * 2 / 3);
        print x;
    }


## Vilkorsatser
#===========

    - if(villkor)
    - else if(villkor)
    - else

    Exempel: 
    if(y < 5)
        return foo(y + 1) + y;
    else
    {
        return (y);
    }
    }


## Operatorer 
#===========
    Proritering
    - 1. %
    - 2. * /
    - 3. + -
    - 4. >= > == != <= <
    - 5. && || !

## Funktioner
#===========
    Exempel:
    int main()
    begin
        int x = 5;
        print x;
        if(foo(1) == 15)
        {
            print 9001;
            break;
        }
        print 10000;
        return x - 3;
    end

## Listor
#===========
    Exempel: 
    list<int> lista; -> []
    lista.insert(0, 5); -> [5]
    lista.insert(1, 3); -> [5, 3]
    lista[0] = 1; -> [1, 3]
    lista.remove(0); -> [3]
    lista.count(); -> 1
 

