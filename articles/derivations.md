# Mathematical derivations

This vignette sets out the mathematics behind the models used in
`mustelus`, step by step. It is intended as a reference for the other
vignettes, which state results without deriving them.

## The von Bertalanffy growth function

The [growth
vignette](https://alharry.github.io/mustelus/articles/growth.md)
introduces the von Bertalanffy growth function as a differential
equation in which growth rate declines linearly as length increases:

``` math
\frac{dL}{dt} = K(L_\infty - L)
```

For an individual animal, age and time advance together, so the rate of
change in length with time is the same as its rate of change with age,
$`a`$. Written in terms of age, the equation is

``` math
\frac{dL}{da} = K(L_\infty - L)
```

The aim is to find length as a function of age, $`L(a)`$.

### The general solution

The equation is separable. Dividing both sides by $`L_\infty - L`$ and
multiplying by $`da`$ puts the terms in $`L`$ on one side and the terms
in $`a`$ on the other:

``` math
\frac{dL}{L_\infty - L} = K \, da
```

Integrating both sides,

``` math
\int \frac{dL}{L_\infty - L} = \int K \, da
```

The left-hand side follows from $`\int dx/(b - x) = -\ln(b - x)`$, which
holds while length is below the asymptote, $`L < L_\infty`$:

``` math
-\ln(L_\infty - L) = Ka + c
```

where $`c`$ is a constant of integration. Multiplying both sides by
$`-1`$ and exponentiating,

``` math
L_\infty - L = e^{-c} e^{-Ka}
```

Writing $`A = e^{-c}`$ for the constant and rearranging gives the
general solution:

``` math
L(a) = L_\infty - A e^{-Ka}
```

The distance remaining to the asymptote, $`L_\infty - L`$, decays
exponentially with age at rate $`K`$. The constant $`A`$ is fixed by any
one known point on the curve, and the choice of that point is what
distinguishes the two forms of the equation.

### In terms of $`t_0`$

Beverton and Holt (1957) fixed the curve by the hypothetical age at
which length would be zero, $`t_0`$. Setting $`L(t_0) = 0`$ in the
general solution,

``` math
0 = L_\infty - A e^{-K t_0}
```

``` math
A = L_\infty e^{K t_0}
```

Substituting this back into the general solution,

``` math
L(a) = L_\infty - L_\infty e^{K t_0} e^{-Ka}
```

and collecting terms gives the familiar form:

``` math
L(a) = L_\infty\left(1 - e^{-K(a - t_0)}\right)
```

### In terms of $`L_0`$

The curve can instead be fixed by length at age zero, $`L_0`$, which for
a chondrichthyan is length at birth. Setting $`L(0) = L_0`$ in the
general solution, and noting that $`e^{0} = 1`$,

``` math
L_0 = L_\infty - A
```

``` math
A = L_\infty - L_0
```

Substituting this back into the general solution,

``` math
L(a) = L_\infty - (L_\infty - L_0)e^{-Ka}
```

Writing $`L_\infty`$ as $`L_0 + (L_\infty - L_0)`$ and collecting the
terms in $`L_\infty - L_0`$ gives the form used by
[`growth()`](https://alharry.github.io/mustelus/reference/growth.md):

``` math
L(a) = L_0 + (L_\infty - L_0)\left(1 - e^{-Ka}\right)
```

### Converting between the two forms

Both forms are the general solution with a different expression for
$`A`$, and they describe the same curve when the two expressions are
equal:

``` math
L_\infty e^{K t_0} = L_\infty - L_0
```

Solving for $`L_0`$,

``` math
L_0 = L_\infty\left(1 - e^{K t_0}\right)
```

and dividing by $`L_\infty`$ and taking logarithms to solve for $`t_0`$,

``` math
t_0 = \frac{1}{K}\ln\left(1 - \frac{L_0}{L_\infty}\right)
```

Because length at birth lies between zero and the asymptote, the term
inside the logarithm lies between zero and one, and $`t_0`$ is negative.
For the example curve in the growth vignette, with $`L_0`$ = 73 cm,
$`L_\infty`$ = 265 cm and $`K`$ = 0.14, this gives $`t_0`$ = -2.3 years.

### Checking the solution

Differentiating the $`L_0`$ form with respect to age,

``` math
\frac{dL}{da} = K(L_\infty - L_0)e^{-Ka}
```

From the general solution with $`A = L_\infty - L_0`$, the distance
remaining to the asymptote is
$`L_\infty - L(a) = (L_\infty - L_0)e^{-Ka}`$. Substituting this in
recovers the original equation:

``` math
\frac{dL}{da} = K\left(L_\infty - L(a)\right)
```

### Time to grow half of the remaining distance

The growth vignette notes that an animal takes $`\ln(2)/K`$ years to
grow half of the remaining distance to $`L_\infty`$, whatever its
current length. From the general solution, the distance remaining at age
$`a`$ is $`L_\infty - L(a) = A e^{-Ka}`$. After a further interval
$`\Delta`$ it is

``` math
L_\infty - L(a + \Delta) = A e^{-K(a + \Delta)} = \left(L_\infty - L(a)\right)e^{-K\Delta}
```

so in any interval of length $`\Delta`$ the remaining distance shrinks
by the same factor, $`e^{-K\Delta}`$. Setting that factor to one half,

``` math
e^{-K\Delta} = \frac{1}{2}
```

``` math
\Delta = \frac{\ln 2}{K}
```

which depends on neither age nor current length. With $`K`$ = 0.14, the
remaining distance halves every 5 years.

## References

Beverton, R.J.H. and Holt, S.J. (1957) *On the Dynamics of Exploited
Fish Populations*. Fishery Investigations Series II, Volume 19. Ministry
of Agriculture, Fisheries and Food, London.

von Bertalanffy, L. (1938) A quantitative theory of organic growth
(inquiries on growth laws. II). *Human Biology* **10**, 181–213.
