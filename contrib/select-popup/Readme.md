# select-popup

## Example
```
(flet ((on-select (item)
                  (lem:message "selected ~A" (car item))))
           (lem-select-popup:start-select-popup 
            (mapcar #'(lambda (x) (cons x #'on-select))
                    '("first" 'second :third))))
```
