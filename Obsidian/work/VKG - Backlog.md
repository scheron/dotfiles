- [ ] - Добавить возможность убирать дельту в ячейках
- [ ] - Добавить возможность 2FA
- [x] - Добавить воскл знак если finres_e === false и тултип что финрез плохой в таблицу портфелей

Update widgets:
- [x] -  admin-companies-table
- [x] -  admin-emails-queue
- [x] -  admin-portfolios
- [x] -  admin-robots-table
- [x] -  admin-servers-table
- [x] -  api-tester
- [x] -  chart-range
- [x] -  deals-history
- [x] -  deals-today
- [x] -  finres-history
- [x] -  finres-today
- [x] -  logs-history
- [x] -  logs-today
- [x] -  market-data-connections
- [x] -  portfolios-table
- [x] -  portfolios-table-chart
- [x] -  robots-table
- [x] -  trans-connections
- [x] -  trans-connections-orders
- [x] -  trans-connections-positions
- [x] -  users-table

Unread messages:
- [x] - В панели Notifications, добавить кнопку More
 > Дозапрашивать предыдущие сообщения
> Она должна отображаться, если есть еще не прочитанные сообщения в базе;
- [x] - Сделать условие если eid нет использовать в качестве его msg. 
> Так как бек в новой версии не будет использовать eid, а будет в качестве него использовать msg.
> Наверное проще, на этапе получения данных сразу делать это, то есть если мне в сообщение не пришел eid, подставлять его как msg `message.eid = message.eid ?? message.msg`
- [x] - В панели Notifications, добавить перед датой текст `Last received: %date%`

Typescript:
- [ ] - Добавить в проект
Utils:
- [ ] - Разобрать @/utils/helpers в другие файлы
- [ ] - Разобрать саму папку @/utils
Modals:
- [ ] - Перевести все модалки на хуки
Widgets: 
Общее:
- [ ] - убрать table из названий виджетов 

        


### Changed
- (Subscription)` - Add `resubscribe` method  & handle `unsubscribe` message while unexpected received from backend
- Add loader on each table loading state
- `(PortfolioFormImport)` -  Change select to combobox.
- `(PortfolioSecurity)` - Add warning while remove `is_first` security.
- Update admin modal styles
- Hide console logs

### Fixed
- Show label if compobobox modelValue type is object.
- `(TelegramSettings)` - Remove header-menu dublicates.
- Undefined key code in securities table.
- Bug, if all robots are disabled.
- `PortfoliosTable` - disable open settings when row disabled

### Added
- Add `Updating Robots` modal while server reconnection
- feat: Add `TimersWorker` for performant timers in web-worker thread.
- Prevent showing `UnreadMessagesNotification` before `5min` delay after login.
- `UserMenu` -> `Notifications` tab -  Add load more messages button.
- Add `watchFields` props to `RefreshWorker` for partial updates by specific columns.
- RobotTable - Add partial watchable fields.
- PortfoliosTable - Add partial watchable fields

### Improved
- Improve `PortfoliosTable` now use BatchAccumulator.
- Improve calculation of disconnectedConnections by accumulator tick instead of each prop has changed.
- Change useFocusWithin lib to native element detection
- Implemented `DeferredMessages` module to defer send message until specific received.
- Rework RefreshWorker for tables cell classes with new BatchAccumulator.
- Improve sorting methods.
- Add accumulation before update for descrese performace impact while onUpdate.
