angular.module('Obfuscate', [])
    .controller('TheController', function($scope, Generator, Ennumerator) {

        $scope.in = ''
        $scope.out = []

        var examples = [
            '12 apples for $5',
            '$10000000',
            'You can get 144.18 pesos for $11',
            '125.5',
            'a list of 5 things',
            '1',
            '2 feet long and 13 feet wide',
            '3456',
            '$0.02',
            '20 hours 36 minutes and 8 seconds remaining'
        ]

        $scope.example = examples[Math.floor(Math.random()*examples.length)]

        $scope.translate = function() {
            $scope.out = []

            if (!$scope.in) 
                return

            $scope.example = examples[Math.floor(Math.random()*examples.length)]

            var options = [],
                parts = $scope.in.split(/\s+/),
                out = [],
                n = 1,
                x

            out.push(parts.join(' '))

            for (var i in parts)
                if (!isNaN(x = parseFloat(parts[i].replace(/^\$/, '')))) {
                    options.push(Generator.generate(x, 
                        (parts[i].indexOf('$') >= 0)))
                    n *= options[options.length - 1].length
                    if (n > 20000) {
                        $scope.out = [ 'something???' ]
                        return
                    }
                }

            if (options && options.length) {
                $scope.starting = false
                var matrix = Ennumerator.process(options)
                for (var i in matrix) {
                    var j = 0, 
                        sentence = ''

                    for (var k in parts) {
                        if (k > 0) 
                            sentence += ' '
                        
                        sentence += isNaN(x = parseFloat(parts[k].replace(/^\$/, ''))) ? 
                            parts[k] :
                            matrix[i][j++]

                        if (k == (parts.length - 1) && j == matrix[i].length) {
                            sentence = sentence.replace(/ ?of([.!?])?$/, '$1')
                            if (parts.length == 1)
                                sentence = sentence.replace(/a ^(mess)/, '')
                        }
                    }

                    out.push(sentence.replace(/^\s+|\s+$/gm,''))
                }
            }

            out.sort(function(a, b) {
                var x = a.length - b.length
                if (!x)
                    x = a > b ? 1 : -1
                return x
            })

            var last = false
            for (var i in out) {
                if (out[i] != last)
                    $scope.out.push(out[i])
                last = out[i]
            }

        }
    })
    .service('Generator', function() {

        var t = [
            {
                range: [-9007199254740992, -1/9007199254740992],
                names: [{single: 'negative', dollars: 'negative dollars'}]
            },
            {
                range: 0,
                names: [
                    { single: '0' },
                    { single: 'no', dollars: 'no money' },
                    { single: 'zero', dollars: 'nothing' }
                ]
            },
            {
                range: [1/9007199254740992, 1],
                names: [
                    { dollars: 'some change' }
                ]
            },
            {
                range: 1,
                names: [
                    { single: 'one', dollars: 'one dollar' },
                    { single: 'a single', dollars: 'a dollar' }
                ]
            },
            {
                range: 2, 
                mod: 2,
                names: [
                    { single: 'a couple of', plural: 'couples of', dollars: 'a couple bucks', pluralDollars: 'couples of dollars' }
                ]
            },
            {
                range: 2,
                noRecurse: true,
                names: [
                    { single: 'a pair of', plural: 'pairs of', condition: 'x == Math.round(x)' }
                ]
            },
            {
                range: 3,
                names: [ { single: 'a trio of', plural: 'trios of' } ]
            },
            {
                range: [3, 11], 
                names: [ { single: 'a few', dollars: 'a few dollars' } ]
            },
            {
                range: [4, 9],
                noRecurse: true,
                names: [ { single: 'a number of', condition: 'x == Math.round(x)' } ]
            },
            {
                range: [4, 10], 
                names: [ { single: 'several', dollars: 'several dollars' } ]
            },
            {
                range: [5, 15],
                names: [ { single: 'a handful of' } ]
            },
            {
                range: 12, 
                names: [ { single: 'a dozen', plural: 'dozens of' } ]
            },
            {
                range: 13,
                names: [ { single: 'a baker\'s dozen', plural: 'baker\'s dozens of' } ]
            },
            {
                range: 20,
                names: [ { single: 'one score', plural: 'score' } ]
            },
            {
                range: [24, 132],
                names: [ { single: 'dozens of', condition: 'Math.floor(x%12) == 0 || Math.ceil(x%12) == 12' } ]
            },
            {
                range: [40, 100],
                mod: 55,
                noRecurse: true,
                names: [
                    { single: 'a bunch of', plural: 'bunches of', dollars: 'a bunch of money' }
                ]
            },
            {
                range: [50, 1111],
                names: [
                    { single: 'lots of', dollars: 'lots of money' }
                ]
            },
            {
                range: [75, 150],
                noRecurse: true,
                names: [
                    { single: 'plenty of', dollars: 'a pretty penny'}
                ]
            },
            {
                range: [50, 1111],
                noRecurse: true,
                names: [
                    { single: 'a mess of' },
                ]
            },
            {
                range: [50, 3050],
                noRecurse: true,
                names: [
                    { single: 'a whole lot of', dollars: 'a whole lot of dollars' },
                ]
            },
            {
                range: [50, 10000],
                noRecurse: true,
                names: [
                    { single: 'plenty of', dollars: 'plenty of money'},
                    { single: 'very many', dollars: 'very many dollars', condition: 'x == Math.round(x)' }
                ]
            },
            {
                range: 144,
                special: function(x, names) {
                    switch (Math.round(x)) {
                        case 36:
                        case 37:
                            names.push((x == 36 ? '' : 'about ') + 'one-quarter gross')
                            break
                        case 71:
                        case 72:
                        case 73:
                            names.push((x == 72 ? '' : 'about ') + 'one-half gross')
                            break
                        case 107:
                        case 108:
                        case 109:
                            names.push((x == 108 ? '' : 'about ') + 'three-quarters gross')
                            break
                        case 143:
                        case 144:
                        case 145:
                            names.push((x == 144 ? '' : 'about ') + 'one gross')
                        case 215:
                        case 216:
                        case 217:
                            names.push((x == 216 ? '' : 'about ') + 'one and a half gross')
                            break
                        case 358:
                        case 359:
                        case 360:
                        case 361:
                        case 362:
                            names.push((x == 360 ? '' : 'about ') + 'two and a half gross')
                            break
                    }
                },
                names: [ { plural: 'gross' } ]
            },
            {
                range: 169,
                special: function(x, names) {
                    switch (Math.round(x)) {
                        case 41:
                        case 42:
                        case 43:
                            names.push((x == 42.25 ? '' : 'about ') + 'one-quarter baker\'s gross')
                            break
                        case 84:
                        case 85:
                        case 86:
                            names.push((x == 84.5 ? '' : 'about ') + 'one-half baker\'s gross')
                            break
                        case 126:
                        case 127:
                        case 128:
                            names.push((x == 126.75 ? '' : 'about ') + 'three-quarters baker\'s gross')
                            break
                        case 253:
                        case 254:
                        case 255:
                            names.push((x == 253.5 ? '' : 'about ') + 'one and a half baker\'s gross')
                            break
                        case 420:
                        case 421:
                        case 422:
                        case 423:
                        case 424:
                        case 425:
                            names.push((x == 422.5 ? '' : 'about ') + 'two and a half baker\'s gross')
                            break
                    }
                },
                names: [ { single: 'baker\'s gross', plural: 'baker\'s gross' } ]
            },
            {
                range: [1112, 9007199254740992],
                noRecurse: true,
                names: [
                    { single: 'a whole mess of' },
                    { single: 'tons of', dollars: 'tons of dollars'}
                ]
            },
            {
                range: 1728,
                names: [ { single: 'great gross of' } ]
            },
            {
                range: [100000, 9007199254740992],
                noRecurse: true,
                names: [
                    { dollars: 'an arm and a leg' },
                    { dollars: 'your firstborn son' }
                ]
            },
            {
                range: [10000000, 9007199254740992],
                noRecurse: true,
                names: [ { dollars: 'a fortune' } ]
            }
        ]

        function gen(x, dollars, plural) {

            var names = []
            for (var i in t) {

                if (typeof t[i].range == 'number' ?  Math.round(x) == t[i].range : 
                        (x >= t[i].range[0] && x <= t[i].range[1])) {

                    for (var j in t[i].names) {
                        if (t[i].names[j].condition && !eval(t[i].names[j].condition))
                            continue
                        var name = dollars ?
                            (plural ? t[i].names[j].pluralDollars : t[i].names[j].dollars) :
                            (plural ? t[i].names[j].plural : t[i].names[j].single)
                        if (name) names.push(name)
                    }
                }

                else if (x > 3) {
                    if (t[i].mod && x / t[i].mod >= 2 && 
                            (!Math.floor(x % t[i].mod) || Math.ceil(x % t[i].mod) == t[i].mod) &&
                            !t[i].noRecurse) {
                        var subNames = gen(x / t[i].mod, dollars, true),
                            modNames = gen(t[i].mod, false, plural)

                        for (var j in subNames)
                            for (var k in modNames)
                                if (modNames[k].indexOf(subNames[j]) == -1)
                                    names.push(modNames[k] + ' ' + subNames[j])

                        if (Math.round(x / t[i].mod) != t[i].mod) {
                            subNames = gen(x / t[i].mod, false, plural)
                            modNames = gen(t[i].mod, dollars, true)
                            for (var j in subNames)
                                for (var k in modNames)
                                    if (subNames[j].indexOf(modNames[k]) == -1)
                                        names.push(subNames[j] + ' ' + modNames[k])
                        }

                    }
                }

                if (!plural && t[i].special)
                    t[i].special(x, names)
            }
            return names
        }

        return {
            generate: gen
        }
    })
    .service('Ennumerator', function() {

        function merge(A, a_Id, B, b_Id, N) {
            N /= A[a_Id].length
            for (var i = 0; i < A[a_Id].length; i++) {
                for (var j = 0; j < N; j++)
                    B[i*N+b_Id+j].push(A[a_Id][i])

                if (a_Id + 1 < A.length)
                    merge(A, a_Id+1, B, b_Id+i*N, N)
            }
        }

        return {
            process: function(A) {
                var B = [],
                    N = 1

                for (var i in A)
                    N *= A[i].length
                
                for (var i = 0; i < N; i++)
                    B.push([])

                merge(A, 0, B, 0, N)
                return B
            }
        }
    })

