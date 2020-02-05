siuba
=====

*scrappy data analysis, with seamless support for pandas and SQL*

[![Build Status](https://travis-ci.org/machow/siuba.svg?branch=master)](https://travis-ci.org/machow/siuba)
[![Documentation Status](https://readthedocs.org/projects/siuba/badge/?version=latest)](https://siuba.readthedocs.io/en/latest/?badge=latest)
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/machow/siuba/master)

<img width="30%" align="right" src="./docs/siuba_small.svg">

siuba is a port of [dplyr](https://github.com/tidyverse/dplyr) and other R libraries. It supports a tabular data analysis workflow centered on 5 common actions:

* `select()` - keep certain columns of data.
* `filter()` - keep certain rows of data.
* `mutate()` - create or modify an existing column of data.
* `summarize()` - reduce one or more columns down to a single number.
* `arrange()` - reorder the rows of data.

These actions can be preceeded by a `group_by()`, which causes them to be applied individually to grouped rows of data. Moreover, many SQL concepts, such as `distinct()`, `count()`, and joins are implemented.
Inputs to these functions can be a pandas `DataFrame` or SQL connection (currently postgres, redshift, or sqlite).

For more on the rationale behind tools like dplyr, see this [tidyverse paper](https://tidyverse.tidyverse.org/articles/paper.html). 
For examples of siuba in action, see the [siuba documentation](https://siuba.readthedocs.io/en/latest/intro.html).

Installation
------------

```
pip install siuba
```

Examples
--------

See the [siuba docs](https://siuba.readthedocs.io) or this [live analysis](https://www.youtube.com/watch?v=eKuboGOoP08) for a full introduction.

### Basic use

The code below uses the example DataFrame `mtcars`, to get the average horsepower (hp) per cylinder.

```python
from siuba import group_by, summarize, _
from siuba.data import mtcars

(mtcars
  >> group_by(_.cyl)
  >> summarize(avg_hp = _.hp.mean())
  )
```

```
Out[1]: 
   cyl      avg_hp
0    4   82.636364
1    6  122.285714
2    8  209.214286
```

There are three key concepts in this example:

| concept | example | meaning |
| ------- | ------- | ------- |
| verb    | `group_by(...)` | a function that operates on a table, like a DataFrame or SQL table |
| siu expression | `_.hp.mean()` | an expression created with `siuba._`, that represents actions you want to perform |
| pipe | `mtcars >> group_by(...)` | a syntax that allows you to chain verbs with the `>>` operator |


See [introduction to siuba](https://siuba.readthedocs.io/en/latest/intro.html#Introduction-to-siuba).

### What is a siu expression (e.g. `_.cyl == 4`)?

A siu expression is a way of specifying **what** action you want to perform.
This allows siuba verbs to decide **how** to execute the action, depending on whether your data is a local DataFrame or remote table.

```python
from siuba import _

_.cyl == 4
```

```
Out[2]:
█─==
├─█─.
│ ├─_
│ └─'cyl'
└─4
```

You can also think siu expressions as a shorthand for a lambda function.

```python
from siuba import _

# lambda approach
mtcars[lambda _: _.cyl == 4]

# siu expression approach
mtcars[_.cyl == 4]
```

```
Out[3]: 
     mpg  cyl   disp   hp  drat     wt   qsec  vs  am  gear  carb
2   22.8    4  108.0   93  3.85  2.320  18.61   1   1     4     1
7   24.4    4  146.7   62  3.69  3.190  20.00   1   0     4     2
..   ...  ...    ...  ...   ...    ...    ...  ..  ..   ...   ...
27  30.4    4   95.1  113  3.77  1.513  16.90   1   1     5     2
31  21.4    4  121.0  109  4.11  2.780  18.60   1   1     4     2

[11 rows x 11 columns]
```

See [siu expression section here](https://siuba.readthedocs.io/en/latest/intro.html#Concise-pandas-operations-with-siu-expressions-(_)).

### Using with SQL

A killer feature of siuba is that the same analysis code can be run on a local DataFrame, or a SQL source.

In the code below, we set up an example database.

```python
# Setup example data ----
from sqlalchemy import create_engine
from siuba.data import mtcars

# copy pandas DataFrame to sqlite
engine = create_engine("sqlite:///:memory:")
mtcars.to_sql("mtcars", engine, if_exists = "replace")
```

Next, we use the code from the first example, except now executed a SQL table.

```python
# Demo SQL analysis with siuba ----
from siuba import _, group_by, summarize, filter
from siuba.sql import LazyTbl

# connect with siuba
tbl_mtcars = LazyTbl(engine, "mtcars")

(tbl_mtcars
  >> group_by(_.cyl)
  >> summarize(avg_hp = _.hp.mean())
  )
```

```
Out[4]: 
# Source: lazy query
# DB Conn: Engine(sqlite:///:memory:)
# Preview:
   cyl      avg_hp
0    4   82.636364
1    6  122.285714
2    8  209.214286
# .. may have more rows
```

See [querying SQL introduction here](https://siuba.readthedocs.io/en/latest/intro_sql_basic.html).

## Comparing `siuba` and `pandas` code

In the code below, 

```python
import pandas as pd

from siuba import _, summarize, filter, mutate

from siuba.data import mtcars

g_cyl = mtcars.groupby('cyl')
```

<sub>
<table>
  <tr>
    <th>group action</th>
    <th>siuba</th>
    <th>pandas</th>
  </tr>
  <tr>
    <td>named aggs</td>
    <td>
      <pre lang="python">
summarize(g_cyl,
  avg_hp = _.hp.mean(),
  avg_mpg = _.mpg.mean()
)</pre>
    </td>
    <td>
      <pre lang="python">
g_cyl.agg(
  avg_hp = pd.NamedAgg("hp", "mean"),
  avg_mpg = pd.NamedAgg("mpg", "mean")
).reset_index()</pre>
    </td>
  </tr>
  <!-- Output -->
  <tr>
    <td></td>
    <td colspan="2">
      <!-- DataFrame -->
<table class="dataframe">  <thead>    <tr style="text-align: right;">      <th></th>      <th>cyl</th>      <th>avg_hp</th>      <th>avg_mpg</th>    </tr>  </thead>  <tbody>    <tr>      <th>0</th>      <td>4</td>      <td>82.636364</td>      <td>26.663636</td>    </tr>    <tr>      <th>1</th>      <td>6</td>      <td>122.285714</td>      <td>19.742857</td>    </tr>    <tr>      <th>2</th>      <td>8</td>      <td>209.214286</td>      <td>15.100000</td>    </tr>  </tbody></table>
      <!-- /end -->
    </td>
  </tr>
  <!-- Example -->
  <tr>
    <td>agg expression</td>
    <td>
      <pre lang="python">
summarize(g_cyl,
  ttl = _.hp.notna().sum()
)</pre>
    </td>
    <td>
      <pre lang="python">
mtcars.hp.notna().groupby("cyl").sum() \
  .reset_index(name = "ttl")</pre>
    </td>
  </tr>
  <!-- Output -->
  <tr>
    <td></td>
    <td colspan="2">
      <!-- DataFrame -->
      <table class="dataframe">  <thead>    <tr style="text-align: right;">      <th></th>      <th>cyl</th>      <th>ttl</th>    </tr>  </thead>  <tbody>    <tr>      <th>0</th>      <td>4</td>      <td>11</td>    </tr>    <tr>      <th>1</th>      <td>6</td>      <td>7</td>    </tr>    <tr>      <th>2</th>      <td>8</td>      <td>14</td>    </tr>  </tbody></table>
      <!-- /end -->
    </td>
  </tr>
  <!-- Example -->
  <tr>
    <td>subtract mean from hp</td>
    <td>
      <pre lang="python">
mutate(g_cyl,
  hp2 = _.hp - _.hp.mean()
)</pre>
    </td>
    <td>
      <pre lang="pyton">
mtcars.assign(
  hp2 = mtcars.hp - g_cyl.hp.transform("mean")
)</pre>
    </td>
  </tr>
  <!-- Output -->
  <tr>
    <td></td>
    <td colspan="2">
      <!-- DataFrame -->
      <table class="dataframe">  <thead>    <tr style="text-align: right;">      <th></th>      <th>cyl</th>      <th>mpg</th>      <th>hp</th>      <th>hp2</th>    </tr>  </thead>  <tbody>    <tr>      <th>0</th>      <td>6</td>      <td>21.0</td>      <td>110</td>      <td>-12.285714</td>    </tr>    <tr>      <th>1</th>      <td>6</td>      <td>21.0</td>      <td>110</td>      <td>-12.285714</td>    </tr>    <tr>      <th>...</th>      <td>...</td>      <td>...</td>      <td>...</td>      <td>...</td>    </tr>    <tr>      <th>30</th>      <td>8</td>      <td>15.0</td>      <td>335</td>      <td>125.785714</td>    </tr>    <tr>      <th>31</th>      <td>4</td>      <td>21.4</td>      <td>109</td>      <td>26.363636</td>    </tr>  </tbody></table>
      <!-- /end -->
    </td>
  </tr>
  <!-- Example -->
  <tr>
    <td>keep lowest mpg rows</td>
    <td>
      <pre lang="python">
filter(g_cyl, _.mpg == _.mpg.min())</pre>
    </td>
    <td>
      <pre lang="python">
mtcars[mtcars.mpg == g_cyl.mpg.transform('min')]</pre>
    </td>
  </tr>
  <!-- Output -->
  <tr>
    <td></td>
    <td colspan="2">
      <!-- DataFrame -->
      <table class="dataframe">  <thead>    <tr style="text-align: right;">      <th></th>      <th>cyl</th>      <th>mpg</th>      <th>hp</th>    </tr>  </thead>  <tbody>    <tr>      <th>0</th>      <td>6</td>      <td>17.8</td>      <td>123</td>    </tr>    <tr>      <th>1</th>      <td>8</td>      <td>10.4</td>      <td>205</td>    </tr>    <tr>      <th>2</th>      <td>8</td>      <td>10.4</td>      <td>215</td>    </tr>    <tr>      <th>3</th>      <td>4</td>      <td>21.4</td>      <td>109</td>    </tr>  </tbody></table>
      <!-- /end -->
    </td>
  </tr>
</table>
</sub>


Testing
-------

Tests are done using pytest.
They can be run using the following.

```bash
# start postgres db
docker-compose up
pytest siuba
```
